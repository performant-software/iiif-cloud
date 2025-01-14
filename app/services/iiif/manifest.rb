module Iiif
  class Manifest
    def self.create(id:, label:, resources:)
      manifest = to_json('manifest.json')
      manifest['id'] = id
      manifest['label'] = {
        en: [label]
      }

      resources.each do |resource|
        manifest['items'] += add_resource(resource)
      end

      JSON.dump(manifest)
    end

    def self.create_for_resource(resource)
      manifest = to_json('manifest.json')
      manifest['id'] = "#{base_url(resource)}/manifest"
      manifest['label'] = {
        en: [resource.name]
      }

      manifest['items'] = add_resource(resource)

      JSON.dump(manifest)
    end

    private

    def self.add_resource(resource)
      items = []

      info = resource_info(resource)

      page_count = info['page_count'] || 1
      width = info['width']
      height = info['height']

      page_count.times do |index|
        items << create_canvas(resource, width, height, index + 1)
      end

      items
    end

    def self.base_url(resource)
      "#{ENV['HOSTNAME']}/public/resources/#{resource.uuid}"
    end

    def self.create_annotation(resource, target, page_number)
      annotation = to_json('annotation.json')
      annotation['id'] = "#{base_url(resource)}/canvas/#{page_number}/page/1/annotation/1"
      annotation['target'] = target

      if resource.image? || resource.pdf?
        id = "#{base_url(resource)};#{page_number}/iiif"
      else
        id = resource.content_url
      end

      if resource.image? || resource.pdf?
        type = 'Image'
      elsif resource.video?
        type = 'Video'
      elsif resource.audio?
        type = 'Sound'
      end

      annotation['body']['id'] = id
      annotation['body']['type'] = type
      annotation['body']['format'] = resource.content_type

      if resource.image? || resource.pdf?
        annotation['body']['service'] = [{
          id: "#{base_url(resource)};#{page_number}",
          type: 'ImageService3',
          profile: 'http://iiif.io/api/image/3/level2.json'
        }]
      end

      annotation
    end

    def self.create_canvas(resource, width, height, page_number)
      canvas = to_json('canvas.json')
      canvas['id'] = "#{base_url(resource)}/canvas/#{page_number}"
      canvas['width'] = width
      canvas['height'] = height
      canvas['label'] = {
        en: [
          resource.name
        ]
      }

      canvas['items'] = [{
        id: "#{base_url(resource)}/canvas/#{page_number}/page/1",
        type: 'AnnotationPage',
        items: [create_annotation(resource, canvas['id'], page_number)]
      }]

      canvas
    end

    def self.resource_info(resource)
      begin
        response = HTTParty.get("#{resource.content_base_url}/info.json")
        info = JSON.parse(response.body)
      rescue
        info = {}
      end

      info
    end

    def self.to_json(filename)
      JSON.parse File.read(File.join(Rails.root, 'templates', filename))
    end
  end
end
