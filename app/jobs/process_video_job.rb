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

  def self.hls_directory(resource)
    [resource.storage_key.presence, HLS_DIRECTORY, resource.uuid].compact.join('/')
  end

  def self.hls_prefix(resource, key = resource.hls_identifier)
    raise ArgumentError, "Missing HLS identifier for resource #{resource.id}" if key.blank?

    "#{hls_directory(resource)}/#{key}"
  end

  def self.master_playlist_key(resource)
    "#{hls_prefix(resource)}/#{Videos::Hls::MASTER_PLAYLIST}"
  end

  private

  def transcode(resource)
    blob = resource.content.blob
    prefix = self.class.hls_prefix(resource, blob.key)
    previously_hls = false

    started = with_current_content(resource, blob) do |current|
      previously_hls = current.hls?
      current.update!(conversion_status: 'processing', conversion_error: nil, conversion_failed_at: nil)
    end

    return unless started

    output_dir = Dir.mktmpdir('hls')

    begin
      CreateManifestJob.perform_later(resource.id) if previously_hls

      blob.open do |file|
        streams = Videos::Hls.probe(file.path)['streams'] || []
        renditions = Videos::Hls.renditions_for(Videos::Hls.source_size(streams))

        Videos::Hls.transcode(file.path, output_dir, renditions, audio: Videos::Hls.audio?(streams))

        upload_ladder(prefix, output_dir)
      end

      previous_hls_identifier = nil

      published = with_current_content(resource, blob) do |current|
        previous_hls_identifier = current.hls_identifier
        current.update!(conversion_status: 'succeeded', conversion_error: nil, conversion_failed_at: nil, hls_identifier: blob.key)
      end

      unless published
        DeleteHlsJob.perform_now(prefix)
        Rails.logger.info "Discarded transcoded video for resource #{resource.id} because its content was replaced"
        return
      end

      if previous_hls_identifier.present? && previous_hls_identifier != blob.key
        DeleteHlsJob.perform_later(self.class.hls_prefix(resource, previous_hls_identifier))
      end

      CreateManifestJob.perform_later(resource.id)

      Rails.logger.info "Successfully transcoded video resource #{resource.id}"
    rescue StandardError => e
      unless record_transcoding_failure(resource, blob, e)
        # The content was replaced or the resource was deleted, so nothing will use these files
        DeleteHlsJob.perform_later(prefix)
        return
      end

      CreateManifestJob.perform_later(resource.id)

      Rails.logger.error "Failed to transcode video resource #{resource.id}: #{e.message}"
      raise
    ensure
      FileUtils.remove_entry(output_dir) if output_dir && Dir.exist?(output_dir)
    end
  end

  # Yields the locked resource if it still exists and its content is still the given blob. Returns the block's value,
  # or nil if the content has changed.
  def with_current_content(resource, blob)
    Resource.transaction do
      current = Resource.lock.find_by(id: resource.id)
      yield current if current&.content_attachment&.blob_id == blob.id
    end
  end

  def upload_ladder(prefix, output_dir)
    service = ActiveStorage::Blob.service
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

  # Returns false if the failure wasn't recorded because the content has changed
  def record_transcoding_failure(resource, blob, error)
    recorded = with_current_content(resource, blob) do |current|
      current.update!(
        conversion_status: 'failed',
        conversion_error: error.message,
        conversion_failed_at: Time.current
      )
    end

    recorded.present?
  rescue StandardError => update_error
    Rails.logger.error "Unable to record video transcoding failure for resource #{resource.id}: #{update_error.message}"
    true
  end
end
