class ResourcesSerializer < BaseSerializer
  # Includes
  include UserDefinedFields::FieldableSerializer

  index_attributes :id, :uuid, :name, :exif, :project_id, :content_url, :content_thumbnail_url, :content_iiif_url,
                   :content_preview_url, :content_download_url, :content_inline_url, :manifest, :content_type

  index_attributes(:manifest_url) { |resource| manifest_url(resource) }

  show_attributes :id, :uuid, :name, :exif, :project_id, :content_url, :content_thumbnail_url, :content_iiif_url,
                  :content_preview_url, :content_download_url, :content_inline_url, :manifest, :content_type,
                  :storage_key, :metadata

  show_attributes(:manifest_url) { |resource| manifest_url(resource) }

  show_attributes(:content_info) { |resource| content_info(resource.content) }
  show_attributes(:content_converted_info) { |resource| content_info(resource.content_converted) }
  show_attributes(:content_converted_pages_info) { |resource| content_pages_info(resource.content_converted_pages) }

  def self.manifest_url(resource)
    "#{ENV['HOSTNAME']}/public/resources/#{resource.uuid}/manifest"
  end

  def self.content_info(attachment)
    return unless attachment.attached?

    {
      key: attachment.key,
      byte_size: attachment.byte_size,
      content_type: attachment.content_type
    }
  end

  # Summary of a PDF's converted pages, stored as one TIFF per page
  def self.content_pages_info(attachments)
    return unless attachments.attached?

    blobs = attachments.blobs

    {
      pages: blobs.size,
      byte_size: blobs.sum(&:byte_size),
      content_type: blobs.first.content_type
    }
  end
end
