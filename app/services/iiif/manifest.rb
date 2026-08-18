module Iiif
  class Manifest
    def self.create(id:, label:, resources:)
      manifest = to_json('manifest.json')
      manifest['id'] = id
      manifest['label'] = {
        en: [label]
      }

      resources.each do |resource|
        manifest['items'] += add_resource(resource, canvas_metadata: true)
      end

      JSON.dump(manifest)
    end

    def self.create_for_resource(resource)
      manifest = to_json('manifest.json')
      manifest['id'] = "#{base_url(resource)}/manifest"
      manifest['label'] = {
        en: [resource.name]
      }

      manifest['items'] = add_resource(resource, canvas_metadata: false)

      metadata = resource_metadata(resource)
      manifest['metadata'] = metadata if metadata.present?

      JSON.dump(manifest)
    end

    private

    def self.add_resource(resource, canvas_metadata: false)
      items = []

      if resource.image? || resource.pdf?
        info = resource_info(resource)
        page_count = info['page_count'] || 1
        height = info['height']
        width = info['width']
      else
        page_count = 1
        height = resource.content&.blob&.metadata[:height]
        width = resource.content&.blob&.metadata[:width]
      end
      
      metadata = canvas_metadata ? resource_metadata(resource) : nil

      page_count.times do |index|
        items << create_canvas(resource, width, height, index + 1, metadata)
      end

      items
    end

    def self.base_url(resource)
      "#{ENV['HOSTNAME']}/public/resources/#{resource.uuid}"
    end

    def self.create_annotation(resource, target, page_number, width, height)
      annotation = to_json('annotation.json')
      annotation['id'] = "#{base_url(resource)}/canvas/#{page_number}/page/1/annotation/1"
      annotation['target'] = target

      if resource.image?
        id = "#{base_url(resource)};#{page_number}/iiif"
      elsif resource.pdf?
        id = resource.content_converted_pages_iiif_url(page_number)
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

      if resource.image? || resource.pdf? || resource.video?
        annotation['body']['height'] = height
        annotation['body']['width'] = width
      end

      if resource.audio? || resource.video?
        annotation['body']['duration'] = resource.content&.blob&.metadata[:duration]
      end

      annotation['body']['id'] = id
      annotation['body']['type'] = type
      annotation['body']['format'] = resource.content_type

      if resource.image? || resource.pdf?
        annotation['body']['service'] = [{
          id: resource.image? ? "#{base_url(resource)};#{page_number}" : resource.content_converted_pages_base_url(page_number),
          type: 'ImageService3',
          profile: 'level2'
        }]
      end

      annotation
    end

    def self.create_canvas(resource, width, height, page_number, metadata = nil)
      canvas = to_json('canvas.json')
      canvas['id'] = "#{base_url(resource)}/canvas/#{page_number}"
      canvas['height'] = height if height
      canvas['width'] = width if width
      canvas['duration'] = resource.content&.blob&.metadata[:duration] if (resource.video? || resource.audio?)
      canvas['label'] = {
        en: [
          resource.name
        ]
      }

      canvas['items'] = [{
        id: "#{base_url(resource)}/canvas/#{page_number}/page/1",
        type: 'AnnotationPage',
        items: [create_annotation(resource, canvas['id'], page_number, width, height)]
      }]

      canvas['metadata'] = metadata if metadata.present?

      canvas
    end

    def self.resource_metadata(resource)
      # use UDFs + metadata column to build metadata JSON
      udf_metadata(resource) + column_metadata(resource)
    end

    def self.udf_metadata(resource)
      return [] unless resource.respond_to?(:user_defined)

      build_metadata(user_defined_fields(resource), resource.user_defined || {})
    end

    def self.column_metadata(resource)
      return [] unless resource.respond_to?(:metadata)

      metadata = resource.metadata
      return [] unless metadata.is_a?(Array)

      metadata.filter_map { |entry| normalize_metadatum(entry) }
    end

    def self.normalize_metadatum(entry)
      # ignore bare strings with no label/value pair, nil, etc
      return nil unless entry.is_a?(Hash)

      # assume hashes are already correct
      return entry if entry['label'].is_a?(Hash) && entry['value'].is_a?(Hash)

      # must have both label and value
      label = entry.key?('label') ? entry['label'] : entry[:label]
      return nil if label.blank?

      # ensure value exists and is/becomes a non-empty array
      value = entry.key?('value') ? entry['value'] : entry[:value]
      values = Array.wrap(value).map { |v| v.to_s }.reject(&:blank?)
      return nil if values.empty?

      # normalize to iiif presentation v3 like { label: { lang: value } }
      {
        label: { en: [label.to_s] },
        value: { en: values }
      }
    end

    def self.user_defined_fields(resource)
      # get UDFs from resource type + project
      query = UserDefinedFields::UserDefinedField.where(table_name: resource.class.to_s)

      project = resource.class.respond_to?(:resolve_defineable) && resource.class.resolve_defineable&.call(resource)

      if project
        query = query.where(defineable_id: project.id, defineable_type: project.class.to_s)
      end

      query.order(:order)
    end

    def self.build_metadata(fields, user_defined)
      # build IIIF Presentation v3 Manifest metadata array
      fields.filter_map do |field|
        value = user_defined[field.uuid]

        values = Array.wrap(value)
                   .map { |v| v.to_s }
                   .reject(&:blank?)

        next if values.empty?

        {
          label: { en: [field.column_name] },
          value: { en: values }
        }
      end
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
