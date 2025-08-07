class CreateManifestJob < ApplicationJob

  # In the event the job is started before the file is fully uploaded, we'll retry
  retry_on Exceptions::FileNotUploadedError, wait: 10.seconds

  def perform(resource_id)
    resource = Resource.find(resource_id)
    return unless resource.iiif?

    raise Exceptions::FileNotUploadedError unless resource.content_uploaded?

    resource.update(manifest: Iiif::Manifest.create_for_resource(resource))
  end
end
