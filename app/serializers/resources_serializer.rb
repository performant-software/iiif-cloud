class ResourcesSerializer < BaseSerializer
  # Includes
  include UserDefinedFields::FieldableSerializer

  index_attributes :id, :uuid, :name, :exif, :project_id, :content_url, :content_thumbnail_url, :content_iiif_url,
                   :content_preview_url, :content_download_url, :content_inline_url, :manifest, :content_type

  index_attributes(:manifest_url) { |resource| manifest_url(resource) }

  show_attributes :id, :uuid, :name, :exif, :project_id, :content_url, :content_thumbnail_url, :content_iiif_url,
                  :content_preview_url, :content_download_url, :content_inline_url, :manifest, :content_type

  show_attributes(:manifest_url) { |resource| manifest_url(resource) }

  show_attributes(:content_info) { |resource| content_info(resource.content) }
  show_attributes(:content_converted_info) { |resource| content_info(resource.content_converted) }

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
end
