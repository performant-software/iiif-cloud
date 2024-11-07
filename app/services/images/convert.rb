module Images
  class Convert
    def self.filename(path, extension)
      "#{File.basename(path, '.*')}.#{extension}"
    end

    def self.to_tiff(file)
      output_file = "#{File.basename(file.path, '.*')}.tif"
      output_path = File.join(File.dirname(file.path), output_file)

      convert = MiniMagick::Tool::Convert.new
      convert << file.path
      convert << '-define'
      convert << 'tiff:tile-geometry=1024x1024'
      convert << '-depth'
      convert << '8'
      convert << '-compress'
      convert << 'jpeg'
      convert << '-alpha'
      convert << 'remove'
      convert << '-colorspace'
      convert << 'sRGB'
      convert << "ptif:#{output_path}"
      convert.call

      output_path
    end
  end
end
