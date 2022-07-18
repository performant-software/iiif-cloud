module Images
  class Exif
    def self.extract(file)
      begin
        data = ::Exif::Data.new(File.open(file.path)).to_h
        encode data
      rescue
        # Do nothing. The image may not contain EXIF data
      end
    end

    private

    def self.encode(hash)
      hash.keys.each do |key|
        value = hash[key]

        if value.is_a?(String)
          hash[key] = hash[key].force_encoding('ISO-8859-1').encode('UTF-8')
        elsif value.is_a?(Hash)
          hash[key] = encode(hash[key])
        end
      end

      hash
    end
  end
end
