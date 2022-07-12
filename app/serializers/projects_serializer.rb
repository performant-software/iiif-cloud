class ProjectsSerializer < BaseSerializer
  index_attributes :id, :uid, :name, :description, :avatar_url, :avatar_thumbnail_url, :organization_id, organization: OrganizationsSerializer
  show_attributes :id, :uid, :name, :description, :api_key, :avatar_url, :organization_id, organization: OrganizationsSerializer
end
