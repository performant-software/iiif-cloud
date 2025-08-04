class ConvertImageJob < ApplicationJob

  CONTENT_TYPE_TIFF = 'image/tiff'
  FILE_EXTENSION_TIFF = 'tif'

  # In the event the job is started before the file is fully uploaded, we'll retry
  retry_on ActiveStorage::FileNotFoundError, wait: 10.seconds

  def perform(resource_id)
    # Only convert if the passed resource is an image
    resource = Resource.find(resource_id)
    return unless resource.image?

    # Only convert if there is content attached
    content = resource.content
    return unless content.attached?

      content.open do |file|
        begin
          # Convert the image
          filepath = Images::Convert.to_tiff(file)
          filename = Images::Convert.filename content.filename.to_s, FILE_EXTENSION_TIFF

          # Upload the converted content
          resource.content_converted.attach(
            io: File.open(filepath),
            content_type: CONTENT_TYPE_TIFF,
            filename:,
          )
        rescue MiniMagick::Error => e
          # Content cannot be converted
          Rails.logger.error e.message
          Rails.logger.error e.backtrace.join("\n")
        end
      end
  end
end
