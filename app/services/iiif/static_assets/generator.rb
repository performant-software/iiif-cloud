module Iiif
  module StaticAssets
    # Generates static, IIIF level 0 compliant image assets, info.json, and a Presentation
    # manifest for a resource, delegating all persistence to the given writer.
    #
    # Writers implement a small duck-typed interface: write(key, bytes), exists?(key), and
    # copy(from_key, to_key). This keeps the generation logic independent of the destination
    # (local disk, cloud storage, an in-memory zip, etc).
    #
    # Images generate a single set of assets/info.json at the resource root. Multi-page PDFs
    # generate assets/info.json per page (under "page/<n>/"), plus a whole-document info.json
    # and a manifest.json with one canvas per page.
    class Generator
      IMAGE_FORMAT = 'jpg'
      ROTATION = '0'
      QUALITY = 'default'

      def initialize(resource:, base_url:, writer:)
        @resource = resource
        @base_url = base_url
        @writer = writer
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

      attr_reader :resource, :base_url, :writer

      def service_url
        @service_url ||= "#{base_url.chomp('/')}/#{resource.id}"
      end

      def call_image
        static_info = write_page_assets(resource.content_base_url, service_url, '')
        writer.write('manifest.json', JSON.pretty_generate(build_manifest([build_canvas(1, service_url, static_info)])))
      end

      def call_pdf
        page_results = (1..resource.page_count).filter_map do |page_number|
          page_base_url = resource.content_converted_pages_base_url(page_number)

          if page_base_url.blank?
            Rails.logger.warn("Skipping static asset generation for #{resource.class}##{resource.id} page #{page_number}: no converted page found")
            next
          end

          page_service_url = "#{service_url}/page/#{page_number}"
          static_info = write_page_assets(page_base_url, page_service_url, "page/#{page_number}/")
          [page_number, static_info]
        end

        raise "No converted pages available for #{resource.class}##{resource.id}" if page_results.empty?

        writer.write('info.json', JSON.pretty_generate(whole_pdf_info(page_results.first.last)))

        canvases = page_results.map { |page_number, info| build_canvas(page_number, "#{service_url}/page/#{page_number}", info) }
        writer.write('manifest.json', JSON.pretty_generate(build_manifest(canvases)))
      end

      # Fetches the source info.json, writes its static assets under key_prefix, and writes a
      # level 0 info.json for it. Returns the generated info.json contents.
      def write_page_assets(source_base_url, page_service_url, key_prefix)
        raise ArgumentError, 'source_base_url is required' if source_base_url.blank?

        source_info = fetch_json("#{source_base_url}/info.json")

        write_iiif_asset(source_base_url, 'full', 'max', key_prefix)

        (source_info['sizes'] || []).each do |size|
          download_iiif_asset(source_base_url, 'full', size['width'], size['height'], key_prefix)
        end

        each_tile(source_info) do |region, width, height|
          download_iiif_asset(source_base_url, region, width, height, key_prefix)
        end

        static_info = level_zero_info(source_info, page_service_url)
        writer.write("#{key_prefix}info.json", JSON.pretty_generate(static_info))
        static_info
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
        info['id'] = service_url if info.key?('id')
        info['@id'] = service_url if info.key?('@id')
        info['page_count'] = resource.page_count
        info
      end

      def build_manifest(canvases)
        {
          '@context' => [
            'http://www.w3.org/ns/anno.jsonld',
            'http://iiif.io/api/presentation/3/context.json'
          ],
          'id' => "#{service_url}/manifest.json",
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
        writer.copy(canonical_key, width_only_key) unless writer.exists?(width_only_key)
      end

      def write_iiif_asset(source_base_url, region, size, key_prefix)
        key = asset_key(region, size, key_prefix)
        return key if writer.exists?(key)

        source_url = "#{source_base_url}/#{region}/#{size}/#{ROTATION}/#{QUALITY}.#{IMAGE_FORMAT}"
        writer.write(key, fetch(source_url).body)
        key
      end

      def asset_key(region, size, key_prefix)
        File.join(*[key_prefix.presence, region, size, ROTATION, "#{QUALITY}.#{IMAGE_FORMAT}"].compact)
      end
    end
  end
end

