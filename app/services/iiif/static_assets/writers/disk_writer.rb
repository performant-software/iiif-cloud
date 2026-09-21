module Iiif
  module StaticAssets
    module Writers
      # Writes generated assets under a resource-scoped directory on the local filesystem.
      class DiskWriter
        def initialize(root)
          @root = root
        end

        def write(key, bytes)
          path = full_path(key)
          FileUtils.mkdir_p(File.dirname(path))
          File.binwrite(path, bytes)
        end

        def exists?(key)
          File.exist?(full_path(key))
        end

        def copy(from_key, to_key)
          to_path = full_path(to_key)
          FileUtils.mkdir_p(File.dirname(to_path))
          FileUtils.cp(full_path(from_key), to_path)
        end

        private

        def full_path(key)
          File.join(@root, key)
        end
      end
    end
  end
end
