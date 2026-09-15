class CreateManifestJob < ApplicationJob

  # In the event the job is started before the file is fully uploaded, we'll retry
  retry_on Exceptions::FileNotUploadedError, wait: 10.seconds

  def perform(resource_id)
    manifest_generated_time = Time.current
    resource = Resource.find(resource_id)
    return unless resource.iiif?

    raise Exceptions::FileNotUploadedError unless resource.content_uploaded?

    resource.update(manifest: Iiif::Manifest.create_for_resource(resource), manifest_generated_at: manifest_generated_time)
  end
end
