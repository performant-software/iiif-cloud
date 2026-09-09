class ConvertImageJob < ApplicationJob

  CONTENT_TYPE_TIFF = 'image/tiff'
  FILE_EXTENSION_TIFF = 'tif'

  # In the event the job is started before the file is fully uploaded, we'll retry
  retry_on Exceptions::FileNotUploadedError, wait: 10.seconds
  retry_on Exceptions::PDFExtractionError, wait: 10.seconds
  retry_on Exceptions::PDFPageConversionError, wait: 10.seconds

  def perform(resource_id)
    resource = Resource.find(resource_id)
    
    # Return early if no content is attached
    content = resource.content
    return unless content.attached?

    raise Exceptions::FileNotUploadedError unless resource.content_uploaded?

    # Route to appropriate converter based on content type
    if resource.image?
      convert_image(resource)
    elsif resource.pdf?
      convert_pdf(resource)
    end
  end

  private

  # Convert a single image file to TIFF
  # Maintains backwards compatibility with existing image conversion workflow
  # @param resource [Resource] The resource containing the image to convert
  def convert_image(resource)
    content = resource.content
    
    content.open do |file|
      begin
        # Convert the image to TIFF using existing service
        filepath = Images::Convert.to_tiff(file)
        filename = Images::Convert.filename content.filename.to_s, FILE_EXTENSION_TIFF

        File.open(filepath) do |converted_file|
          converted_blob = create_and_upload_converted_blob!(
            io: converted_file,
            content_type: CONTENT_TYPE_TIFF,
            filename:,
            metadata: { storage_key: resource.storage_key },
          )

          begin
            resource.content_converted.attach(converted_blob)

            unless ActiveStorage::Attachment.exists?(record: resource, name: 'content_converted', blob: converted_blob)
              raise ActiveRecord::RecordNotSaved, 'Unable to attach converted content'
            end
          rescue StandardError
            converted_blob.purge
            raise
          end
        end
      rescue MiniMagick::Error => e
        # Content cannot be converted - log and continue (non-fatal)
        Rails.logger.error "Error converting image for resource #{resource.id}: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
      ensure
        # Clean up temporary file
        File.delete(filepath) if filepath && File.exist?(filepath)
      end
    end
  end

  # Convert a multi-page PDF to an ordered set of TIFF files
  # @param resource [Resource] The resource containing the PDF to convert
  def convert_pdf(resource)
    content = resource.content
    temp_files = []
    converted_blobs = []
    published = false

    begin
      resource.update!(conversion_status: 'processing', conversion_error: nil, conversion_failed_at: nil)

      content.open do |file|
        # Extract page count from PDF
        page_count = Images::ConvertPdf.page_count(file)
        
        # Process each page
        page_count.times do |page_number|
          begin
            # Extract page as intermediate image
            temp_image_path = Images::ConvertPdf.extract_page(file, page_number)
            temp_files << temp_image_path

            # Convert extracted page to TIFF
            tiff_path = Images::ConvertPdf.page_to_tiff(File.new(temp_image_path))
            temp_files << tiff_path

            # Generate filename for this page (e.g., "document_page_001.tif")
            base_filename = File.basename(content.filename.to_s, '.*')
            page_filename = "#{base_filename}_page_#{page_number + 1}.#{FILE_EXTENSION_TIFF}"

            File.open(tiff_path) do |converted_file|
              converted_blob = create_and_upload_converted_blob!(
                io: converted_file,
                content_type: CONTENT_TYPE_TIFF,
                filename: page_filename,
                metadata: { original_page_number: page_number + 1, storage_key: resource.storage_key },
              )
              converted_blobs << converted_blob
            end

            # Clean up intermediate files as we go
            Images::ConvertPdf.cleanup_temp_files([temp_image_path, tiff_path])
            temp_files -= [temp_image_path, tiff_path]
          end
        end

        resource.with_lock do
          resource.content_converted_pages = converted_blobs
          resource.pages_count = page_count
          resource.conversion_status = 'succeeded'
          resource.conversion_error = nil
          resource.conversion_failed_at = nil
          resource.save!
        end

        published = true

        # Regenerate manifest only after the complete page set is published.
        CreateManifestJob.perform_later(resource.id)

        Rails.logger.info "Successfully converted PDF resource #{resource.id} with #{page_count} pages"
      end
    rescue StandardError => e
      unless published
        purge_blobs(converted_blobs)
        record_pdf_conversion_failure(resource, e)
      end
      Rails.logger.error "Failed to convert PDF resource #{resource.id}: #{e.message}"
      raise
    ensure
      # Ensure all temporary files are cleaned up
      Images::ConvertPdf.cleanup_temp_files(temp_files)
    end
  end

  def create_and_upload_converted_blob!(io:, content_type:, filename:, metadata: nil)
    converted_blob = ActiveStorage::Blob.create_after_unfurling!(
      io:,
      content_type:,
      filename:,
      metadata:
    )
    converted_blob.upload_without_unfurling(io)
    converted_blob
  rescue StandardError
    converted_blob&.purge
    raise
  end

  def purge_blobs(blobs)
    blobs.each do |blob|
      blob.purge
    rescue StandardError => e
      Rails.logger.error "Unable to purge staged blob #{blob.id}: #{e.message}"
    end
  end

  def record_pdf_conversion_failure(resource, error)
    resource.reload
    resource.update!(
      conversion_status: 'failed',
      conversion_error: error.message,
      conversion_failed_at: Time.current
    )
  rescue StandardError => update_error
    Rails.logger.error "Unable to record PDF conversion failure for resource #{resource.id}: #{update_error.message}"
  end
end
