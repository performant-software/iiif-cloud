class ResourcesSerializer < BaseSerializer
  index_attributes :id, :name, :metadata, :exif, :project_id, :content_thumbnail_url, :content_type
  show_attributes :id, :name, :metadata, :exif, :project_id, :content_url, :content_preview_url, :content_download_url, :manifest, :content_type
end
