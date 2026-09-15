require 'tmpdir'

class ProcessVideoJob < ApplicationJob

  HLS_DIRECTORY = 'hls'

  retry_on Exceptions::FileNotUploadedError, wait: 10.seconds

  def perform(resource_id)
    resource = Resource.find(resource_id)

    return unless resource.content.attached?

    return unless resource.video?

    raise Exceptions::FileNotUploadedError unless resource.content_uploaded?

    transcode(resource)
  end

  def self.hls_prefix(resource)
    [resource.storage_key.presence, HLS_DIRECTORY, resource.uuid].compact.join('/')
  end

  def self.master_playlist_key(resource)
    "#{hls_prefix(resource)}/#{Videos::Hls::MASTER_PLAYLIST}"
  end

  private

  def transcode(resource)
    output_dir = Dir.mktmpdir('hls')

    begin
      previously_hls = resource.hls?

      resource.update!(conversion_status: 'processing', conversion_error: nil, conversion_failed_at: nil)

      CreateManifestJob.perform_later(resource.id) if previously_hls

      resource.content.open do |file|
        streams = Videos::Hls.probe(file.path)['streams'] || []
        renditions = Videos::Hls.renditions_for(Videos::Hls.source_size(streams))

        Videos::Hls.transcode(file.path, output_dir, renditions, audio: Videos::Hls.audio?(streams))

        upload_ladder(resource, output_dir)
      end

      resource.update!(conversion_status: 'succeeded', conversion_error: nil, conversion_failed_at: nil)

      CreateManifestJob.perform_later(resource.id)

      Rails.logger.info "Successfully transcoded video resource #{resource.id}"
    rescue StandardError => e
      record_transcoding_failure(resource, e)

      CreateManifestJob.perform_later(resource.id)

      Rails.logger.error "Failed to transcode video resource #{resource.id}: #{e.message}"
      raise
    ensure
      FileUtils.remove_entry(output_dir) if output_dir && Dir.exist?(output_dir)
    end
  end

  def upload_ladder(resource, output_dir)
    service = ActiveStorage::Blob.service
    prefix = self.class.hls_prefix(resource)
    root = Pathname.new(output_dir)

    DeleteHlsJob.perform_now(prefix)

    Dir.glob(File.join(output_dir, '**', '*')).sort.each do |path|
      next if File.directory?(path)

      key = "#{prefix}/#{Pathname.new(path).relative_path_from(root)}"

      File.open(path, 'rb') do |io|
        service.upload(key, io, content_type: Videos::Hls.content_type_for(path))
      end
    end
  end

  def record_transcoding_failure(resource, error)
    resource.reload
    resource.update!(
      conversion_status: 'failed',
      conversion_error: error.message,
      conversion_failed_at: Time.current
    )
  rescue StandardError => update_error
    Rails.logger.error "Unable to record video transcoding failure for resource #{resource.id}: #{update_error.message}"
  end
end
