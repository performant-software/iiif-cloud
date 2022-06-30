class Api::UsersController < Api::BaseController
  # Search attributes
  search_attributes :name, :email

  # Preloads
  preloads user_organizations: :organization, only: :show
end
