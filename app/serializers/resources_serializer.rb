class ResourcesSerializer < BaseSerializer
  index_attributes :id, :name, :metadata, :exif, :project_id, :content_url, :content_thumbnail_url
  show_attributes :id, :name, :metadata, :exif, :project_id, :content_url
end
