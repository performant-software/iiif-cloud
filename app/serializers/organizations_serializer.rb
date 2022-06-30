class OrganizationsSerializer < BaseSerializer
  index_attributes :id, :name, :location
  show_attributes :id, :name, :location, user_organizations: [:id, :user_id, user: UsersSerializer]
end
