class ConvertImageJob < ApplicationJob
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
        filename = Images::Convert.filename(content.filename.to_s, 'tif')

        # Upload the converted content
        resource.content_converted.attach(
          io: File.open(filepath),
          filename:  filename,
          content_type: 'image/tiff'
        )

      rescue MiniMagick::Error => e
        # Content cannot be converted
        Rails.logger.error e.message
        Rails.logger.error e.backtrace.join("\n")
      end
    end
  end
end
