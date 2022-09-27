class ResourcesSerializer < BaseSerializer
  # Includes
  include UserDefinedFields::FieldableSerializer

  index_attributes :id, :uuid, :name, :exif, :project_id, :content_url, :content_thumbnail_url, :content_iiif_url,
                   :content_preview_url, :content_download_url, :manifest, :content_type
  show_attributes :id, :uuid, :name, :exif, :project_id, :content_url, :content_thumbnail_url, :content_iiif_url,
                  :content_preview_url, :content_download_url, :manifest, :content_type
end
