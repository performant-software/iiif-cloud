class ProjectsSerializer < BaseSerializer
  # Includes
  include UserDefinedFields::DefineableSerializer

  index_attributes :id, :name, :description, :avatar_thumbnail_url, :organization_id, organization: OrganizationsSerializer
  show_attributes :id, :name, :description, :avatar_url, :avatar_preview_url, :uuid, :organization_id, organization: OrganizationsSerializer
end
