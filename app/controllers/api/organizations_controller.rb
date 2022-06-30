class Api::OrganizationsController < Api::BaseController
  # Search attributes
  search_attributes :name, :location

  # Preloads
  preloads user_organizations: :user, only: :show
end
