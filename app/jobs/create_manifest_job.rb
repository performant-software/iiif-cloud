class CreateManifestJob < ApplicationJob

  # In the event the job is started before the file is fully uploaded, we'll retry
  retry_on ActiveStorage::FileNotFoundError, wait: 10.seconds

  def perform(resource_id)
    resource = Resource.find(resource_id)
    return unless resource.iiif?

    resource.update(manifest: Iiif::Manifest.create_for_resource(resource))
  end
end
