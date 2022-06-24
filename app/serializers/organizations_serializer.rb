class OrganizationsSerializer < BaseSerializer
  index_attributes :id, :name, :location
  show_attributes :id, :name, :location
end
