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
        output = MiniMagick.identify { |b| b << file.path }

        # Parse output to extract page count
        # ImageMagick identify on a PDF returns one line per page, e.g. "file.pdf[3] PDF ..."
        pages = output.scan(/\[(\d+)\]/).flatten.uniq.count
        
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

    # Max DPI or DPI for pages without a raster source (vector/text)
    MAX_DENSITY = 300

    # Min DPI
    MIN_DENSITY = 72

    # Rendering density per page (0-indexed), taken from the largest embedded image on the
    # page
    #
    # @param file [File] The PDF file
    # @param page_count [Integer] Number of pages in the PDF
    # @return [Array<Integer>] Density to render each page at
    def self.page_densities(file, page_count)
      native = native_page_densities(file)

      Array.new(page_count) do |page_number|
        density = native[page_number] || MAX_DENSITY
        density.clamp(MIN_DENSITY, MAX_DENSITY)
      end
    end

    # Convert a single PDF page to a pyramidal TIFF
    #
    # @param file [File] The PDF file
    # @param page_number [Integer] The page number (0-indexed)
    # @param density [Integer] Rendering density in DPI
    # @return [String] Path to the converted TIFF file
    # @raise [Exceptions::PDFPageConversionError] If the page cannot be converted
    def self.page_to_tiff(file, page_number, density = MAX_DENSITY)
      begin
        base_filename = File.basename(file.path, '.*')
        output_filename = "#{base_filename}_page_#{page_number + 1}.tif"
        output_path = File.join(File.dirname(file.path), output_filename)

        convert = MiniMagick.convert
        convert << '-density'
        convert << density.to_s
        convert << "#{file.path}[#{page_number}]"  # Specify page index (0-indexed)
        convert << '-define'
        convert << 'tiff:tile-geometry=1024x1024'
        convert << '-define'
        convert << 'ptif:pyramid=1024x8'
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

        raise Exceptions::PDFPageConversionError, 'Output file not created' unless File.exist?(output_path)

        output_path
      rescue MiniMagick::Error => e
        raise Exceptions::PDFPageConversionError, "Failed to convert page #{page_number} to TIFF: #{e.message}"
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

    # Native resolution of each page's largest embedded image, keyed by 0-indexed page
    # number. Pages with no embedded image (vector/text) are absent from the result.
    #
    # Reads the x-ppi/y-ppi columns of `pdfimages -list`, which report the resolution an
    # image is placed at, i.e. the density that renders it 1:1.
    # @param file [File] The PDF file
    # @return [Hash{Integer => Integer}] Page number to native density
    def self.native_page_densities(file)
      output = `pdfimages -list #{Shellwords.escape(file.path)} 2>/dev/null`
      return {} unless $?&.success?

      largest = {}

      output.each_line do |line|
        fields = line.split
        # page num type width height color comp bpc enc interp object ID x-ppi y-ppi size ratio
        next unless fields.size >= 14 && fields[2] == 'image'

        page_number = Integer(fields[0], exception: false)
        width = Integer(fields[3], exception: false)
        height = Integer(fields[4], exception: false)
        x_ppi = Float(fields[12], exception: false)
        y_ppi = Float(fields[13], exception: false)
        next if page_number.nil? || width.nil? || height.nil? || x_ppi.nil? || y_ppi.nil?
        next unless x_ppi.positive? && y_ppi.positive?

        # Page numbers are 1-indexed here; the rest of the conversion is 0-indexed.
        index = page_number - 1
        pixels = width * height
        next if largest[index] && largest[index][:pixels] >= pixels

        largest[index] = { pixels:, density: [x_ppi, y_ppi].max.ceil }
      end

      largest.transform_values { |image| image[:density] }
    rescue StandardError => e
      # Density detection is an optimization; fall back to rendering at MAX_DENSITY.
      Rails.logger.warn("Unable to detect native page densities: #{e.message}")
      {}
    end

    # Alternative method to count PDF pages using string-based parsing
    # This is a fallback if the primary method fails
    # @param file [File] The PDF file
    # @return [Integer] The number of pages
    def self.count_pdf_pages_alternative(file)
      # Read PDF file and count /Type /Page objects as a rough estimate
      # This is a simple heuristic and may not work for all PDF types
      pdf_content = File.read(file.path, encoding: 'ISO-8859-1')
      
      # Count /Type /Page occurrences, excluding /Type /Pages tree/container nodes
      count = pdf_content.scan(%r{/Type\s*/Page(?!s)}).count
      count = 1 if count.zero?  # At minimum, a PDF has 1 page
      
      count
    end
  end
end
