module Iiif
  module StaticAssets
    module Writers
      # Uploads generated assets to an S3-compatible static storage bucket (Cloudflare R2 in
      # practice, but anything implementing the S3 API works), under a resource-scoped key prefix.
      #
      # Credentials are always required explicitly (no environment-variable fallback) - the
      # intent is that each caller supplies its own narrowly-scoped, often short-lived credential
      # (e.g. one limited to read/write access under a single destination prefix) rather than this
      # process holding one long-lived, bucket-wide credential that every caller shares. The one
      # exception is #from_env, a separate explicit opt-in for local/dev tooling (e.g. the iiif
      # rake tasks) that has no per-request credential to draw from.
      #
      # endpoint/region are always read from this process's own environment, never accepted as
      # caller-supplied parameters - a caller-controlled endpoint would let a request be directed
      # at an arbitrary host.
      class StorageWriter
        def initialize(prefix, bucket:, access_key_id:, secret_access_key:, session_token: nil)
          @prefix = prefix
          @bucket = bucket
          @client = Aws::S3::Client.new(**{
            access_key_id: access_key_id,
            secret_access_key: secret_access_key,
            session_token: session_token,
            endpoint: ENV['STATIC_STORAGE_ENDPOINT'].presence,
            region: ENV.fetch('STATIC_STORAGE_REGION', 'auto'),
            force_path_style: true
          }.compact)
        end

        # Builds a writer from this process's own environment-configured credentials. Only
        # intended for callers with no per-request credential of their own (currently just the
        # local/dev rake tasks) - everything else should be given its own scoped credentials.
        def self.from_env(prefix)
          new(
            prefix,
            bucket: ENV.fetch('STATIC_STORAGE_BUCKET'),
            access_key_id: ENV.fetch('STATIC_STORAGE_ACCESS_KEY_ID'),
            secret_access_key: ENV.fetch('STATIC_STORAGE_SECRET_ACCESS_KEY')
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

        # Without this, the bucket stores uploads as application/octet-stream, which makes
        # browsers download the file instead of rendering it (e.g. a manifest.json link).
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
