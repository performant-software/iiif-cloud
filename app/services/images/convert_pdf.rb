module Images
  class ConvertPdf
    # Extract the total number of pages from a PDF file
    # @param file [File] The PDF file to analyze
    # @return [Integer] The number of pages in the PDF
    # @raise [Exceptions::PDFExtractionError] If PDF cannot be read or is corrupted
    def self.page_count(file)
      begin
        # Use ImageMagick to identify PDF structure
        # We need to count the actual pages available
        identify = MiniMagick::Tool::Identify.new
        identify << file.path
        output = identify.call

        # Parse output to extract page count
        # ImageMagick identify on a PDF returns info for each page
        pages = output.scan(/\d+(?=\[0\]|\[\d+\])/m).count
        
        if pages.zero?
          # Fallback: try to use pdftoppm or count with strings
          pages = count_pdf_pages_alternative(file)
        end

        raise Exceptions::EmptyPDFError, "PDF has no extractable pages" if pages.zero?

        pages
      rescue MiniMagick::Error => e
        raise Exceptions::PDFExtractionError, "Failed to extract page count from PDF: #{e.message}"
      end
    end

    # Extract a single page from PDF as an intermediate image file
    # @param file [File] The PDF file
    # @param page_number [Integer] The page number (0-indexed)
    # @param output_format [String] Output image format (default: 'png')
    # @return [String] Path to the extracted image file
    # @raise [Exceptions::PDFExtractionError] If page extraction fails
    def self.extract_page(file, page_number, output_format = 'png')
      begin
        # Generate output filename with page number
        base_filename = File.basename(file.path, '.*')
        output_filename = "#{base_filename}_page_#{page_number + 1}.#{output_format}"
        output_path = File.join(File.dirname(file.path), output_filename)

        # Use ImageMagick to extract the specific PDF page
        convert = MiniMagick.convert
        convert << "#{file.path}[#{page_number}]"  # Specify page index (0-indexed)
        convert << '-quality'
        convert << '85'  # Good quality for intermediate conversion
        convert << '-density'
        convert << '300'  # High DPI for better quality
        convert << output_path
        convert.call

        raise Exceptions::PDFExtractionError, "Output file not created" unless File.exist?(output_path)

        output_path
      rescue MiniMagick::Error => e
        raise Exceptions::PDFExtractionError, "Failed to extract page #{page_number} from PDF: #{e.message}"
      end
    end

    # Convert an extracted PDF page (as image) to TIFF format
    # @param image_file [File] The intermediate image file (result of extract_page)
    # @return [String] Path to the converted TIFF file
    # @raise [Exceptions::PDFPageConversionError] If conversion fails
    def self.page_to_tiff(image_file)
      begin
        output_file = "#{File.basename(image_file.path, '.*')}.tif"
        output_path = File.join(File.dirname(image_file.path), output_file)

        convert = MiniMagick.convert
        convert << image_file.path
        convert << '-density'
        convert << '300'
        convert << '-define'
        convert << 'tiff:tile-geometry=1024x1024'
        convert << '-depth'
        convert << '8'
        convert << '-compress'
        convert << 'jpeg'
        convert << '-strip'
        convert << '-alpha'
        convert << 'remove'
        convert << '-alpha'
        convert << 'off'
        convert << '-colorspace'
        convert << 'sRGB'
        convert << "ptif:#{output_path}"
        convert.call

        output_path
      rescue MiniMagick::Error => e
        raise Exceptions::PDFPageConversionError, "Failed to convert page to TIFF: #{e.message}"
      end
    end

    # Clean up temporary intermediate image files
    # @param file_paths [Array<String>] Paths to temporary files to delete
    def self.cleanup_temp_files(file_paths)
      file_paths.each do |filepath|
        File.delete(filepath) if File.exist?(filepath)
      rescue Errno::ENOENT
        # File already deleted, no action needed
      rescue StandardError => e
        Rails.logger.warn("Failed to cleanup temp file #{filepath}: #{e.message}")
      end
    end

    private

    # Alternative method to count PDF pages using string-based parsing
    # This is a fallback if the primary method fails
    # @param file [File] The PDF file
    # @return [Integer] The number of pages
    def self.count_pdf_pages_alternative(file)
      # Read PDF file and count /Type /Page objects as a rough estimate
      # This is a simple heuristic and may not work for all PDF types
      pdf_content = File.read(file.path, encoding: 'ISO-8859-1')
      
      # Count /Type /Page occurrences
      count = pdf_content.scan(%r{/Type\s*/Page(?!/s)}).count
      count = 1 if count.zero?  # At minimum, a PDF has 1 page
      
      count
    end
  end
end
