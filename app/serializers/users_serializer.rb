class UsersSerializer < BaseSerializer
  index_attributes :id, :name, :email
  show_attributes :id, :name, :email, user_organizations: [:id, :organization_id, organization: OrganizationsSerializer]
end
