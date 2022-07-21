class UsersSerializer < BaseSerializer
  index_attributes :id, :name, :email, :admin, :avatar_thumbnail_url
  show_attributes :id, :name, :email, :admin, :avatar_url, :avatar_preview_url, user_organizations: [:id, :organization_id, organization: OrganizationsSerializer]
end
