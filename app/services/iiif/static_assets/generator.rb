module Iiif
  module StaticAssets
    # Generates static, IIIF level 0 compliant image assets, info.json, and a Presentation
    # manifest for a resource, delegating all persistence to the given writer.
    #
    # Writers implement a small duck-typed interface: write(key, bytes), exists?(key), and
    # copy(from_key, to_key). This keeps the generation logic independent of the destination
    # (local disk, cloud storage, an in-memory zip, etc).
    #
    # Images generate a single set of assets/info.json at iiif/image/v3/{identifier}. Multi-page
    # PDFs generate assets/info.json per page (under ".../page/<n>/"), plus a whole-document
    # info.json. Either way, the manifest is written to
    # iiif/presentation/v3/{identifier}/manifest.json.
    class Generator
      IMAGE_FORMAT = 'jpg'
      ROTATION = '0'
      QUALITY = 'default'
      # Fetches (per page, and per size/tile within a page) are independent HTTP requests to
      # Cantaloupe, so running a bounded number of them concurrently cuts wall-clock time
      # substantially without changing what gets generated.
      MAX_CONCURRENCY = 8

      def initialize(resource:, base_url:, identifier:, writer:)
        @resource = resource
        @base_url = base_url
        @identifier = identifier
        @writer = writer
        @writer_mutex = Mutex.new
      end

      def call
        if resource.pdf?
          call_pdf if resource.converted_pages?
        elsif resource.image?
          call_image
        end

        writer.respond_to?(:finalize) ? writer.finalize : nil
      end

      private

      attr_reader :resource, :base_url, :identifier, :writer

      def image_root
        @image_root ||= "iiif/image/v3/#{identifier}"
      end

      def image_service_url
        @image_service_url ||= "#{base_url.chomp('/')}/#{image_root}"
      end

      def manifest_key
        @manifest_key ||= "iiif/presentation/v3/#{identifier}/manifest.json"
      end

      def manifest_url
        @manifest_url ||= "#{base_url.chomp('/')}/#{manifest_key}"
      end

      def call_image
        static_info = write_page_assets(resource.content_base_url, image_service_url, "#{image_root}/")
        writer_write(manifest_key, JSON.pretty_generate(build_manifest([build_canvas(1, image_service_url, static_info)])))
      end

      def call_pdf
        page_results = parallel_map((1..resource.page_count).to_a) do |page_number|
          page_base_url = resource.content_converted_pages_base_url(page_number)

          if page_base_url.blank?
            Rails.logger.warn("Skipping static asset generation for #{resource.class}##{resource.id} page #{page_number}: no converted page found")
            next
          end

          page_service_url = "#{image_service_url}/page/#{page_number}"
          static_info = write_page_assets(page_base_url, page_service_url, "#{image_root}/page/#{page_number}/")
          [page_number, static_info]
        end.compact

        raise "No converted pages available for #{resource.class}##{resource.id}" if page_results.empty?

        writer_write("#{image_root}/info.json", JSON.pretty_generate(whole_pdf_info(page_results.first.last)))

        canvases = page_results.map { |page_number, info| build_canvas(page_number, "#{image_service_url}/page/#{page_number}", info) }
        writer_write(manifest_key, JSON.pretty_generate(build_manifest(canvases)))
      end

      # Fetches the source info.json, writes its static assets under key_prefix, and writes a
      # level 0 info.json for it. Returns the generated info.json contents.
      def write_page_assets(source_base_url, page_service_url, key_prefix)
        raise ArgumentError, 'source_base_url is required' if source_base_url.blank?

        source_info = fetch_json("#{source_base_url}/info.json")

        max_key = write_iiif_asset(source_base_url, 'full', 'max', key_prefix)

        parallel_each(source_info['sizes'] || []) do |size|
          if size['width'] == source_info['width'] && size['height'] == source_info['height']
            # This "sizes" entry is identical to what we already fetched as /full/max/. Both
            # paths still need to exist for level 0 compliance (a viewer may request either), so
            # reuse those bytes via a local copy instead of re-fetching the same image.
            copy_full_size_asset(max_key, size['width'], size['height'], key_prefix)
          else
            download_iiif_asset(source_base_url, 'full', size['width'], size['height'], key_prefix)
          end
        end

        tile_requests = []
        each_tile(source_info) { |region, width, height| tile_requests << [region, width, height] }
        parallel_each(tile_requests) do |region, width, height|
          download_iiif_asset(source_base_url, region, width, height, key_prefix)
        end

        static_info = level_zero_info(source_info, page_service_url)
        writer_write("#{key_prefix}info.json", JSON.pretty_generate(static_info))
        static_info
      end

      # Processes items in bounded-size batches, running each batch's work concurrently on
      # threads. Exceptions from any thread propagate to the caller (same as a plain #each).
      def parallel_each(items)
        items.each_slice(MAX_CONCURRENCY) do |batch|
          batch.map { |item| Thread.new { yield item } }.each(&:join)
        end
      end

      # Like parallel_each, but collects and returns the block's results in the original order.
      def parallel_map(items)
        items.each_slice(MAX_CONCURRENCY).flat_map do |batch|
          batch.map { |item| Thread.new { yield item } }.map(&:value)
        end
      end

      def copy_full_size_asset(max_key, width, height, key_prefix)
        canonical_key = asset_key('full', "#{width},#{height}", key_prefix)
        writer_copy(max_key, canonical_key) unless writer_exists?(canonical_key)

        width_only_key = asset_key('full', "#{width},", key_prefix)
        writer_copy(max_key, width_only_key) unless writer_exists?(width_only_key)
      end

      def each_tile(source_info)
        (source_info['tiles'] || []).each do |tile_config|
          width = tile_config['width']
          height = tile_config['height'] || width
          scale_factors = tile_config['scaleFactors'] || []

          scale_factors.each do |scale|
            tile_w = width * scale
            tile_h = height * scale

            (0...source_info['width']).step(tile_w) do |x|
              (0...source_info['height']).step(tile_h) do |y|
                rw = [tile_w, source_info['width'] - x].min
                rh = [tile_h, source_info['height'] - y].min

                calc_w = (rw.to_f / scale).ceil
                calc_h = (rh.to_f / scale).ceil
                yield "#{x},#{y},#{rw},#{rh}", calc_w, calc_h
              end
            end
          end
        end
      end

      def fetch(url)
        response = HTTParty.get(url)
        return response if response.success?

        raise "Unable to fetch #{url}: #{response.code} #{response.message}"
      end

      def fetch_json(url)
        JSON.parse(fetch(url).body)
      end

      def level_zero_info(source_info, target_service_url)
        info = source_info.deep_dup
        info['id'] = target_service_url if info.key?('id')
        info['@id'] = target_service_url if info.key?('@id')
        %w[extraQualities extraFormats].each { |attribute| info.delete(attribute) }
        # We generate both `w,h` and `w,` variants, so advertise width-only size requests as supported
        info['extraFeatures'] = ['sizeByW']
        info['profile'] = 'level0'
        info
      end

      # A multi-page PDF has no single IIIF Image API representation, so this is a lightweight
      # summary (first page's dimensions plus the page count) rather than a fetched info.json.
      def whole_pdf_info(first_page_info)
        info = first_page_info.deep_dup
        info['id'] = image_service_url if info.key?('id')
        info['@id'] = image_service_url if info.key?('@id')
        info['page_count'] = resource.page_count
        info
      end

      def build_manifest(canvases)
        {
          '@context' => [
            'http://www.w3.org/ns/anno.jsonld',
            'http://iiif.io/api/presentation/3/context.json'
          ],
          'id' => manifest_url,
          'type' => 'Manifest',
          'label' => { 'en' => [resource.name] },
          'items' => canvases
        }
      end

      def build_canvas(index, canvas_service_url, info)
        canvas_url = "#{canvas_service_url}/canvas/#{index}"
        image_url = "#{canvas_service_url}/full/max/0/default.#{IMAGE_FORMAT}"

        {
          'id' => canvas_url,
          'type' => 'Canvas',
          'width' => info['width'],
          'height' => info['height'],
          'items' => [{
            'id' => "#{canvas_url}/page/1",
            'type' => 'AnnotationPage',
            'items' => [{
              'id' => "#{canvas_url}/page/1/annotation/1",
              'type' => 'Annotation',
              'motivation' => 'painting',
              'body' => {
                'id' => image_url,
                'type' => 'Image',
                'format' => "image/#{IMAGE_FORMAT}",
                'width' => info['width'],
                'height' => info['height'],
                'service' => [{
                  'id' => canvas_service_url,
                  'type' => 'ImageService3',
                  'profile' => 'level0'
                }]
              },
              'target' => canvas_url
            }]
          }]
        }
      end

      # Some viewers request sizes as "w,h" and others request width-only as "w,". Since these are
      # static files (no server-side content negotiation), we write the same bytes to both size
      # keys, fetching from the source only once per region.
      def download_iiif_asset(source_base_url, region, width, height, key_prefix)
        canonical_key = write_iiif_asset(source_base_url, region, "#{width},#{height}", key_prefix)

        width_only_key = asset_key(region, "#{width},", key_prefix)
        writer_copy(canonical_key, width_only_key) unless writer_exists?(width_only_key)
      end

      def write_iiif_asset(source_base_url, region, size, key_prefix)
        key = asset_key(region, size, key_prefix)
        return key if writer_exists?(key)

        source_url = "#{source_base_url}/#{region}/#{size}/#{ROTATION}/#{QUALITY}.#{IMAGE_FORMAT}"
        writer_write(key, fetch(source_url).body)
        key
      end

      def asset_key(region, size, key_prefix)
        File.join(*[key_prefix.presence, region, size, ROTATION, "#{QUALITY}.#{IMAGE_FORMAT}"].compact)
      end

      def writer_write(key, bytes)
        @writer_mutex.synchronize { writer.write(key, bytes) }
      end

      def writer_exists?(key)
        @writer_mutex.synchronize { writer.exists?(key) }
      end

      def writer_copy(from_key, to_key)
        @writer_mutex.synchronize { writer.copy(from_key, to_key) }
      end
    end
  end
end

