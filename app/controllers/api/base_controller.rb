class Api::BaseController < Api::ResourceController
  # Includes
  include JwtAuth::Authenticateable

  # Actions
  before_action :authenticate_request

  protected

  def check_authorization(organization_id)
    deny_access unless current_user.has_access?(organization_id)
  end

  def deny_access
    render json: { errors: [I18n.t('errors.unauthorized')] }, status: :forbidden
  end
end
