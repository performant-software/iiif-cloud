class CreateStaticAssetsJob < ApplicationJob

  def perform(resource_id, base_url, destination, identifier: nil, local: false)
    resource = Resource.find(resource_id)
    writer = writer_for(destination, local:)

    Iiif::StaticAssets::Generator.new(
      resource: resource,
      base_url: base_url,
      identifier: identifier || resource.uuid,
      writer: writer
    ).call
  end

  private

  # Assets are uploaded to R2 by default; pass local: true (e.g. for local development) to
  # write them to disk instead. `destination` is the shared root both writers write under; the
  # Generator itself lays out the iiif/image/v3 and iiif/presentation/v3 paths beneath it.
  def writer_for(destination, local:)
    return Iiif::StaticAssets::Writers::DiskWriter.new(destination) if local

    Iiif::StaticAssets::Writers::R2Writer.new(destination)
  end
end

