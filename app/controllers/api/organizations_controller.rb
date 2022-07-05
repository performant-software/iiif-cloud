class Api::OrganizationsController < Api::BaseController
  # Search attributes
  search_attributes :name, :location

  # Preloads
  preloads user_organizations: :user, only: :show

  # Actions
  before_action :deny_access, unless: -> { current_user.admin? }, only: [:create, :update, :destroy]

  protected

  def base_query
    return super if current_user.admin?

    Organization.where(
      UserOrganization
        .where(UserOrganization.arel_table[:organization_id].eq(Organization.arel_table[:id]))
        .where(user_id: current_user.id)
        .arel
        .exists
    )
  end
end
