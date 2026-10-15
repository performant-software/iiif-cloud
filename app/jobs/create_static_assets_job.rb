class CreateStaticAssetsJob < ApplicationJob

  # Retries a transient failure (e.g. a network blip hitting Cantaloupe) a few times with
  # increasing backoff before recording it as a final failure. This runs *after* retries are
  # exhausted (rather than on every attempt, as a plain rescue would) specifically so that a
  # caller polling the job status endpoint never sees "failed" while Sidekiq might still retry
  # successfully, and so short-lived storage credentials attached to the job aren't recorded as a
  # failure reason when they're really just a retry in progress.
  #
  # Declared before the more specific PDFNotConvertedError handler below so that the latter takes
  # priority for that exception (ActiveSupport::Rescuable matches declared handlers in reverse
  # order, so the last-declared matching handler wins).
  retry_on StandardError, wait: :polynomially_longer, attempts: 3 do |job, error|
    options = job.arguments.last.is_a?(Hash) ? job.arguments.last : {}
    job_uuid = options[:job_uuid]
    resource_id = job.arguments.first

    job.send(:record_outcome, job_uuid, resource_id, JobItem::STATUS_FAILED, error: error.message)
  end

  # A PDF resource whose pages haven't finished converting yet isn't ready for static asset
  # generation (see Iiif::StaticAssets::Generator#call) - retried on its own longer timeline
  # (rather than exhausting the generic StandardError retries above) since conversion may simply
  # still be in progress.
  retry_on Exceptions::PDFNotConvertedError, wait: 10.seconds

  # job_uuid is optional so this job remains callable the way it always has been (e.g. from tests
  # or other callers that don't care about tracking); tracking is simply skipped when it's absent.
  def perform(resource_id, base_url, destination, identifier: nil, local: false, job_uuid: nil)
    resource = Resource.find(resource_id)
    writer = writer_for(destination, local:, job_uuid:)

    Iiif::StaticAssets::Generator.new(
      resource: resource,
      base_url: base_url,
      identifier: identifier || resource.uuid,
      writer: writer
    ).call

    record_outcome(job_uuid, resource_id, JobItem::STATUS_COMPLETED)
  end

  private

  # Assets are uploaded to static storage by default; pass local: true (e.g. for local
  # development) to write them to disk instead. `destination` is the shared root both writers
  # write under; the Generator itself lays out the iiif/3/image and iiif/3/presentation paths
  # beneath it.
  #
  # job_uuid is blank only for callers with no per-job credential to draw from (currently just
  # the local/dev rake tasks), which fall back to this process's own ENV-configured storage
  # credentials via StorageWriter.from_env. Every other caller is expected to have stored its own
  # scoped credentials on the Job row via Public::ResourcesController#create_static_assets - there
  # is deliberately no silent fallback for that case; a missing credential is a configuration bug
  # that should surface as a failure, not quietly use a shared one instead.
  def writer_for(destination, local:, job_uuid: nil)
    return Iiif::StaticAssets::Writers::DiskWriter.new(destination) if local
    return Iiif::StaticAssets::Writers::StorageWriter.from_env(destination) if job_uuid.blank?

    Iiif::StaticAssets::Writers::StorageWriter.new(destination, **storage_credentials(job_uuid))
  end

  def storage_credentials(job_uuid)
    credentials = Job.find_by(uuid: job_uuid)&.extra&.[]('storage_credentials')
    raise ArgumentError, "No storage credentials stored for job #{job_uuid}" if credentials.blank?

    credentials.symbolize_keys.slice(:bucket, :access_key_id, :secret_access_key, :session_token)
  end

  def record_outcome(job_uuid, resource_id, status, error: nil)
    return if job_uuid.blank?

    JobItem.record_outcome!(job_uuid: job_uuid, resource_id: resource_id, status: status, error: error)
  end
end

