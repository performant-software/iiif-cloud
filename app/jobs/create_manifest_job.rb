class CreateManifestJob < ApplicationJob
  def perform(resource_id)
    resource = Resource.find(resource_id)
    return unless resource.iiif?

    resource.update(manifest: Iiif::Manifest.create_for_resource(resource))
  end
end
