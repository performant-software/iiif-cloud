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

        # Upload the converted content to content_converted (single file attachment)
        resource.content_converted.attach(
          io: File.open(filepath),
          content_type: CONTENT_TYPE_TIFF,
          filename:,
        )
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

    begin
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

            # Attach TIFF to content_converted_pages in order
            resource.content_converted_pages.attach(
              io: File.open(tiff_path),
              content_type: CONTENT_TYPE_TIFF,
              filename: page_filename,
            )

            # Clean up intermediate files as we go
            Images::ConvertPdf.cleanup_temp_files([temp_image_path, tiff_path])
            temp_files -= [temp_image_path, tiff_path]

          rescue Exceptions::PDFExtractionError => e
            Rails.logger.error "Failed to extract page #{page_number} from PDF for resource #{resource.id}: #{e.message}"
            # Continue with next page rather than failing entire job
          rescue Exceptions::PDFPageConversionError => e
            Rails.logger.error "Failed to convert page #{page_number} to TIFF for resource #{resource.id}: #{e.message}"
            # Continue with next page rather than failing entire job
          end
        end

        # Store page count on resource for tracking
        resource.update(pages_count: page_count)

        Rails.logger.info "Successfully converted PDF resource #{resource.id} with #{page_count} pages"

      end
    rescue Exceptions::EmptyPDFError => e
      Rails.logger.error "PDF resource #{resource.id} is empty: #{e.message}"
    rescue Exceptions::PDFExtractionError => e
      Rails.logger.error "Failed to extract pages from PDF resource #{resource.id}: #{e.message}"
    ensure
      # Ensure all temporary files are cleaned up
      Images::ConvertPdf.cleanup_temp_files(temp_files)
    end
  end
end
