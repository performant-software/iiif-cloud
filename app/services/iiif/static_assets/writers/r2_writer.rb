module Iiif
  module StaticAssets
    module Writers
      # Uploads generated assets to a Cloudflare R2 (S3-compatible) bucket, under a resource-scoped
      # key prefix. Credentials/endpoint/bucket default to environment variables, but a caller can
      # pass its own (e.g. a narrowly-scoped, short-lived credential minted for a single static
      # build run) to avoid relying on this process's own blanket-access R2 credentials.
      class R2Writer
        def initialize(prefix, bucket: nil, access_key_id: nil, secret_access_key: nil, endpoint: nil)
          @prefix = prefix
          @bucket = bucket || ENV.fetch('R2_BUCKET')
          @client = Aws::S3::Client.new(
            access_key_id: access_key_id || ENV.fetch('R2_ACCESS_KEY_ID'),
            secret_access_key: secret_access_key || ENV.fetch('R2_SECRET_ACCESS_KEY'),
            endpoint: endpoint || ENV.fetch('R2_ENDPOINT'),
            region: 'auto',
            force_path_style: true
          )
        end

        def write(key, bytes)
          client.put_object(bucket: bucket, key: full_key(key), body: bytes, content_type: content_type_for(key))
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

        attr_reader :bucket, :client

        def full_key(key)
          File.join(@prefix, key)
        end

        def copy_source(key)
          escaped_key = full_key(key).split('/').map { |segment| CGI.escape(segment) }.join('/')
          "#{bucket}/#{escaped_key}"
        end

        # Without this, R2 stores uploads as application/octet-stream, which makes browsers
        # download the file instead of rendering it (e.g. a manifest.json link).
        def content_type_for(key)
          case File.extname(key)
          when '.json' then 'application/json'
          when '.jpg', '.jpeg' then 'image/jpeg'
          else 'application/octet-stream'
          end
        end
      end
    end
  end
end
