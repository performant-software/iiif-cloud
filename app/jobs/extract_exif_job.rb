class ExtractExifJob < ApplicationJob

  # In the event the job is started before the file is fully uploaded, we'll retry
  retry_on Exceptions::FileNotUploadedError, wait: 10.seconds

  def perform(resource_id)
    resource = Resource.find(resource_id)
    return unless resource.content.image?

    raise Exceptions::FileNotUploadedError unless resource.content_uploaded?

    exif = nil

    begin
      resource.content.open do |file|
        image_data = MiniMagick::Image.open(file.path)
        exif = JSON.dump(image_data.data) if image_data&.data.present?
      end
    rescue StandardError => e
      Rails.logger.error e.message
      Rails.logger.error e.backtrace.join("\n")
    end

    resource.update(exif: exif)
  end
end
