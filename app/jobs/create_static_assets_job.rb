class CreateStaticAssetsJob < ApplicationJob

  def perform(resource_id, base_url, destination, local: false)
    resource = Resource.find(resource_id)
    writer = writer_for(destination, resource_id, local:)

    Iiif::StaticAssets::Generator.new(resource: resource, base_url: base_url, writer: writer).call
  end

  private

  # Assets are uploaded to R2 by default; pass local: true (e.g. for local development) to
  # write them to disk instead. Either way, `destination` is scoped per-resource.
  def writer_for(destination, resource_id, local:)
    root = File.join(destination, resource_id.to_s)

    return Iiif::StaticAssets::Writers::DiskWriter.new(root) if local

    Iiif::StaticAssets::Writers::R2Writer.new(root)
  end
end

