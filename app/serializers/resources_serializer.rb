class ResourcesSerializer < BaseSerializer
  # Includes
  include UserDefinedFields::FieldableSerializer

  index_attributes :id, :uuid, :name, :exif, :project_id, :content_url, :content_thumbnail_url, :content_iiif_url,
                   :content_preview_url, :content_download_url, :content_inline_url, :manifest, :content_type

  index_attributes(:manifest_url) { |resource| manifest_url(resource) }

  show_attributes :id, :uuid, :name, :exif, :project_id, :content_url, :content_thumbnail_url, :content_iiif_url,
                  :content_preview_url, :content_download_url, :content_inline_url, :manifest, :content_type

  show_attributes(:manifest_url) { |resource| manifest_url(resource) }

  def self.manifest_url(resource)
    "#{ENV['HOSTNAME']}/public/resources/#{resource.uuid}/manifest"
  end
end
