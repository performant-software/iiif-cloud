class Api::UsersController < Api::BaseController
  # Search attributes
  search_attributes :name, :email

  # Preloads
  preloads User.attachment_preloads
  preloads user_organizations: :organization, only: :show

  # Actions
  before_action :validate_new_user, unless: -> { current_user.admin? }, only: :create
  before_action :validate_user, unless: -> { current_user.admin? }, only: [:update, :destroy]

  protected

  def base_query
    return super if current_user.admin?

    User.where(
      UserOrganization
        .where(UserOrganization.arel_table[:user_id].eq(User.arel_table[:id]))
        .where(organization_id: current_user.user_organizations.pluck(:id))
        .arel
        .exists
    )
  end

  private

  def validate_new_user
    organization_ids = params[:user][:user_organizations].map{ |uo| uo[:organization_id] }
    check_authorization organization_ids
  end

  def validate_user
    user = User.find(params[:id])
    organization_ids = user.user_organizations.pluck(:organization_id)
    check_authorization organization_ids
  end
end
