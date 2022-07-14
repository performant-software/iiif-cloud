module Images
  class Manifest
    def self.create(resource)
      manifest = to_json('manifest.json')
      manifest['id'] = "#{resource.uuid}/manifest.json"
      manifest['label'] = {
        en: [resource.name]
      }
      manifest['items'] = [create_canvas(resource)]

      JSON.dump(manifest)
    end

    private

    def self.create_annotation(resource)
      annotation = to_json('annotation.json')
      annotation['id'] = "#{resource.uuid}/annotation/p1"
      annotation['body']['id'] = resource.content_url
      annotation['body']['type'] = 'Image'
      annotation['body']['format'] = resource.content_type
      annotation['body']['height'] = resource.content_metadata['height']
      annotation['body']['width'] = resource.content_metadata['width']
      annotation['body']['service'] = [{
        '@id': resource.content_base_url,
        '@type': "ImageService2",
        profile: 'http://iiif.io/api/image/2/level2.json',
      }]

      annotation
    end

    def self.create_canvas(resource)
      canvas = to_json('canvas.json')
      canvas['id'] = "#{resource.uuid}/canvas/p1"
      canvas['height'] = resource.content_metadata['height']
      canvas['width'] = resource.content_metadata['width']
      canvas['items'] = [{
        id: "#{resource.uuid}/canvas/p1/1",
        items: [create_annotation(resource)]
      }]

      canvas
    end

    def self.to_json(filename)
      file = File.read(File.join(Rails.root, 'templates', filename))
      JSON.parse(file)
    end
  end
end
