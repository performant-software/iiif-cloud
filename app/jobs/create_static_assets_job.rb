require 'fileutils'

class CreateStaticAssetsJob < ApplicationJob

	IMAGE_FORMAT = 'jpg'

	def perform(resource_id, base_url, output_folder)
		resource = Resource.find(resource_id)

    # Return if the resource is not an image
    # (We'll deal with PDFs later)
    return unless resource.image?

		source_base_url = resource.content_base_url
		source_info = fetch_json("#{source_base_url}/info.json")

		service_url = "#{base_url.chomp('/')}/#{resource_id}"
		output_path = File.join(output_folder, resource_id.to_s)
		image_path = File.join(output_path, 'full', 'max', '0', "default.#{IMAGE_FORMAT}")

		FileUtils.mkdir_p(File.dirname(image_path))
		File.binwrite(image_path, fetch("#{source_base_url}/full/max/0/default.#{IMAGE_FORMAT}").body)

		sizes = source_info['sizes'] || []
		tiles = source_info['tiles'] || []
    
    sizes.each do |size|
			download_iiif_asset(source_base_url, 'full', "#{size['width']},#{size['height']}", output_path)
    end

    tiles.each do |tile_config|
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
            
            region = "#{x},#{y},#{rw},#{rh}"
            calc_w = (rw.to_f / scale).ceil
						calc_h = (rh.to_f / scale).ceil 
						download_iiif_asset(source_base_url, region, "#{calc_w},#{calc_h}", output_path)
          end
        end
      end
    end

		static_info = level_zero_info(source_info, service_url)
		File.write(File.join(output_path, 'info.json'), JSON.pretty_generate(static_info))
		File.write(File.join(output_path, 'manifest.json'), JSON.pretty_generate(manifest(resource, service_url, static_info)))
	end

	private

	def fetch(url)
		response = HTTParty.get(url)
		return response if response.success?

		raise "Unable to fetch #{url}: #{response.code} #{response.message}"
	end

	def fetch_json(url)
		JSON.parse(fetch(url).body)
	end

	def level_zero_info(source_info, service_url)
		info = source_info.deep_dup
		info['id'] = service_url if info.key?('id')
		info['@id'] = service_url if info.key?('@id')
		%w[extraQualities extraFormats extraFeatures].each { |attribute| info.delete(attribute) }
		info['profile'] = 'level0'
		info
	end

	def manifest(resource, service_url, info)
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

	def download_iiif_asset(source_base_url, region, size, dest_root)
		rotation = '0'
		quality = 'default'
		format = IMAGE_FORMAT
		source_url = "#{source_base_url}/#{region}/#{size}/#{rotation}/#{quality}.#{format}"
		target_dir = File.join(dest_root, region, size, rotation)
    FileUtils.mkdir_p(target_dir)
    target_file = File.join(target_dir, "#{quality}.#{format}")

    unless File.exist?(target_file)
			File.binwrite(target_file, fetch(source_url).body)
    end
  end
end
