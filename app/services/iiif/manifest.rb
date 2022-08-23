module Iiif
  class Manifest
    def self.create(resource)
      manifest = to_json('manifest.json')
      manifest['id'] = "https://#{resource.uuid}"
      manifest['label'] = {
        en: [resource.name]
      }

      items = []

      page_count(resource).times do |index|
        items << create_canvas(resource, index + 1)
      end

      manifest['items'] = items

      JSON.dump(manifest)
    end

    private

    def self.create_annotation(resource, target, page_number)
      annotation = to_json('annotation.json')
      annotation['id'] = "https://#{resource.uuid}/canvas/#{page_number}/annotation_page/1/annotation/1"
      annotation['target'] = target

      if resource.image? || resource.pdf?
        id = resource.content_iiif_url(page_number)
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
          id: "#{resource.content_base_url};#{page_number}",
          type: 'ImageService3',
          profile: 'http://iiif.io/api/image/3/level2.json'
        }]
      end

      annotation
    end

    def self.create_canvas(resource, page_number)
      canvas = to_json('canvas.json')
      canvas['id'] = "https://#{resource.uuid}/canvas/#{page_number}"

      canvas['items'] = [{
        id: "https://#{resource.uuid}/canvas/#{page_number}/annotation_page/1",
        type: 'AnnotationPage',
        items: [create_annotation(resource, canvas['id'], page_number)]
      }]

      canvas
    end

    def self.page_count(resource)
      page_count = 1

      begin
        response = HTTParty.get("#{resource.content_base_url}/info.json")
        context = JSON.parse(response.body)
        page_count = context['page_count'] || 1
      rescue
        # Do nothing. There's a possibility there may be no response from the server.
      end

      page_count
    end

    def self.to_json(filename)
      JSON.parse File.read(File.join(Rails.root, 'templates', filename))
    end
  end
end
