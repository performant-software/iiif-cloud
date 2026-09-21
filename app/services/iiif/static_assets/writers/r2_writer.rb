module Iiif
  module StaticAssets
    module Writers
      # Uploads generated assets to a Cloudflare R2 (S3-compatible) bucket, under a resource-scoped
      # key prefix. Credentials/endpoint are read from environment variables so that the same
      # writer works across environments without code changes.
      class R2Writer
        def initialize(prefix)
          @prefix = prefix
        end

        def write(key, bytes)
          client.put_object(bucket: bucket, key: full_key(key), body: bytes)
        end

        def exists?(key)
          client.head_object(bucket: bucket, key: full_key(key))
          true
        rescue Aws::S3::Errors::NotFound
          false
        end

        # Uses a server-side copy so the bytes aren't re-uploaded from this process.
        def copy(from_key, to_key)
          client.copy_object(
            bucket: bucket,
            copy_source: copy_source(from_key),
            key: full_key(to_key)
          )
        end

        private

        def full_key(key)
          File.join(@prefix, key)
        end

        def copy_source(key)
          escaped_key = full_key(key).split('/').map { |segment| CGI.escape(segment) }.join('/')
          "#{bucket}/#{escaped_key}"
        end

        def bucket
          ENV.fetch('R2_BUCKET')
        end

        def client
          @client ||= Aws::S3::Client.new(
            access_key_id: ENV.fetch('R2_ACCESS_KEY_ID'),
            secret_access_key: ENV.fetch('R2_SECRET_ACCESS_KEY'),
            endpoint: ENV.fetch('R2_ENDPOINT'),
            region: 'auto',
            force_path_style: true
          )
        end
      end
    end
  end
end
