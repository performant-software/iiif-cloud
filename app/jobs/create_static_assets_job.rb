class CreateStaticAssetsJob < ApplicationJob

  # job_uuid is optional so this job remains callable the way it always has been (e.g. from tests
  # or other callers that don't care about tracking); tracking is simply skipped when it's absent.
  def perform(resource_id, base_url, destination, identifier: nil, local: false, job_uuid: nil)
    resource = Resource.find(resource_id)
    writer = writer_for(destination, local:)

    Iiif::StaticAssets::Generator.new(
      resource: resource,
      base_url: base_url,
      identifier: identifier || resource.uuid,
      writer: writer
    ).call

    record_outcome(job_uuid, resource_id, JobItem::STATUS_COMPLETED)
  rescue StandardError => e
    # Recorded immediately for status-polling visibility. Sidekiq's own default retry behavior for
    # this job is unchanged (this re-raises), so a subsequent successful retry will simply
    # overwrite this outcome to "completed" via the upsert in JobItem.record_outcome!.
    record_outcome(job_uuid, resource_id, JobItem::STATUS_FAILED, error: e.message)
    raise
  end

  private

  # Assets are uploaded to R2 by default; pass local: true (e.g. for local development) to
  # write them to disk instead. `destination` is the shared root both writers write under; the
  # Generator itself lays out the iiif/3/image and iiif/3/presentation paths beneath it.
  def writer_for(destination, local:)
    return Iiif::StaticAssets::Writers::DiskWriter.new(destination) if local

    Iiif::StaticAssets::Writers::R2Writer.new(destination)
  end

  def record_outcome(job_uuid, resource_id, status, error: nil)
    return if job_uuid.blank?

    JobItem.record_outcome!(job_uuid: job_uuid, resource_id: resource_id, status: status, error: error)
  end
end

