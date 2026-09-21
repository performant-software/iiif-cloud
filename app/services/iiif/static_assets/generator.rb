module Iiif
  module StaticAssets
    # Generates static, IIIF level 0 compliant image assets, info.json, and a Presentation
    # manifest for a resource, delegating all persistence to the given writer.
    #
    # Writers implement a small duck-typed interface: write(key, bytes), exists?(key), and
    # copy(from_key, to_key). This keeps the generation logic independent of the destination
    # (local disk, cloud storage, an in-memory zip, etc).
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
        # Return if the resource is not an image
        # (We'll deal with PDFs later)
        return unless resource.image?

        source_info = fetch_json("#{source_base_url}/info.json")

        write_iiif_asset(source_base_url, 'full', 'max')

        (source_info['sizes'] || []).each do |size|
          download_iiif_asset(source_base_url, 'full', size['width'], size['height'])
        end

        each_tile(source_info) do |region, width, height|
          download_iiif_asset(source_base_url, region, width, height)
        end

        static_info = level_zero_info(source_info)
        writer.write('info.json', JSON.pretty_generate(static_info))
        writer.write('manifest.json', JSON.pretty_generate(manifest(static_info)))

        writer.respond_to?(:finalize) ? writer.finalize : nil
      end

      private

      attr_reader :resource, :base_url, :writer

      def source_base_url
        @source_base_url ||= resource.content_base_url
      end

      def service_url
        @service_url ||= "#{base_url.chomp('/')}/#{resource.id}"
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

      def level_zero_info(source_info)
        info = source_info.deep_dup
        info['id'] = service_url if info.key?('id')
        info['@id'] = service_url if info.key?('@id')
        %w[extraQualities extraFormats].each { |attribute| info.delete(attribute) }
        # We generate both `w,h` and `w,` variants, so advertise width-only size requests as supported
        info['extraFeatures'] = ['sizeByW']
        info['profile'] = 'level0'
        info
      end

      def manifest(info)
        manifest_url = "#{service_url}/manifest.json"
        canvas_url = "#{service_url}/canvas/1"
        image_url = "#{service_url}/full/max/0/default.#{IMAGE_FORMAT}"

        {
          '@context' => [
            'http://www.w3.org/ns/anno.jsonld',
            'http://iiif.io/api/presentation/3/context.json'
          ],
          'id' => manifest_url,
          'type' => 'Manifest',
          'label' => { 'en' => [resource.name] },
          'items' => [{
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
                    'id' => service_url,
                    'type' => 'ImageService3',
                    'profile' => 'level0'
                  }]
                },
                'target' => canvas_url
              }]
            }]
          }]
        }
      end

      # Some viewers request sizes as "w,h" and others request width-only as "w,". Since these are
      # static files (no server-side content negotiation), we write the same bytes to both size
      # keys, fetching from the source only once per region.
      def download_iiif_asset(source_base_url, region, width, height)
        canonical_key = write_iiif_asset(source_base_url, region, "#{width},#{height}")

        width_only_key = asset_key(region, "#{width},")
        writer.copy(canonical_key, width_only_key) unless writer.exists?(width_only_key)
      end

      def write_iiif_asset(source_base_url, region, size)
        key = asset_key(region, size)
        return key if writer.exists?(key)

        source_url = "#{source_base_url}/#{region}/#{size}/#{ROTATION}/#{QUALITY}.#{IMAGE_FORMAT}"
        writer.write(key, fetch(source_url).body)
        key
      end

      def asset_key(region, size)
        File.join(region, size, ROTATION, "#{QUALITY}.#{IMAGE_FORMAT}")
      end
    end
  end
end
