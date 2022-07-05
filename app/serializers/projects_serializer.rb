class ProjectsSerializer < BaseSerializer
  index_attributes :id, :uid, :name, :description, :organization_id, organization: OrganizationsSerializer
  show_attributes :id, :uid, :name, :description, :api_key, :organization_id, organization: OrganizationsSerializer
end
