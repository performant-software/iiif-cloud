class ExtractExifJob < ApplicationJob
  def perform(resource_id)
    resource = Resource.find(resource_id)
    return unless resource.content.image?

    resource.content.open do |file|
      data = Images::Exif.extract(file)

      if data.present?
        resource.update(exif: JSON.dump(data))
      end
    end
  end
end
