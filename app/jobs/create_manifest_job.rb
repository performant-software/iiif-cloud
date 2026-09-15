class CreateManifestJob < ApplicationJob

  # In the event the job is started before the file is fully uploaded, we'll retry
  retry_on Exceptions::FileNotUploadedError, wait: 10.seconds

  def perform(resource_id)
    resource = Resource.find(resource_id)
    return unless resource.iiif?

    raise Exceptions::FileNotUploadedError unless resource.content_uploaded?

    analyze_content(resource) if resource.audio? || resource.video?

    resource.update(manifest: Iiif::Manifest.create_for_resource(resource))
  end

  private

  def analyze_content(resource)
    blob = resource.content.blob
    return if blob.metadata[:duration].present?

    blob.analyze
    blob.reload
  rescue StandardError => e
    Rails.logger.error "Unable to analyze content for resource #{resource.id}: #{e.message}"
  end
end
