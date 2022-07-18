module Iiif
  class Manifest
    def self.create(resource)
      manifest = to_json('manifest.json')
      manifest['id'] = "https://#{resource.uuid}"
      manifest['label'] = {
        en: [resource.name]
      }
      manifest['items'] = [create_canvas(resource)]

      JSON.dump(manifest)
    end

    private

    def self.create_annotation(resource, target)
      annotation = to_json('annotation.json')
      annotation['id'] = "https://#{resource.uuid}/canvas/1/annotation_page/1/annotation/1"
      annotation['target'] = target
      annotation['body']['id'] = resource.content_url
      annotation['body']['type'] = 'Image'
      annotation['body']['format'] = 'image/jpeg'
      annotation['body']['service'] = [{
        id: resource.content_base_url,
        type: 'ImageService2',
        profile: 'http://iiif.io/api/image/2/level2.json'
      }]

      annotation
    end

    def self.create_canvas(resource)
      canvas = to_json('canvas.json')
      canvas['id'] = "https://#{resource.uuid}/canvas/1"
      canvas['items'] = [{
        id: "https://#{resource.uuid}/canvas/1/annotation_page/1",
        type: 'AnnotationPage',
        items: [create_annotation(resource, canvas['id'])]
      }]

      canvas
    end

    def self.to_json(filename)
      file = File.read(File.join(Rails.root, 'templates', filename))
      JSON.parse(file)
    end
  end
end
