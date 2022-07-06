class UsersSerializer < BaseSerializer
  index_attributes :id, :name, :email, :admin, :avatar_url
  show_attributes :id, :name, :email, :admin, :avatar_url, user_organizations: [:id, :organization_id, organization: OrganizationsSerializer]
end
