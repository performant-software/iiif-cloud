class ProjectsSerializer < BaseSerializer
  index_attributes :id, :uid, :name, :description, :avatar_thumbnail_url, :organization_id, organization: OrganizationsSerializer
  show_attributes :id, :uid, :name, :description, :api_key, :avatar_url, :avatar_preview_url, :organization_id, organization: OrganizationsSerializer
end
