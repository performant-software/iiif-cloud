class Api::BaseController < Api::ResourceController
  # Actions
  before_action :authenticate_request

  protected

  def authenticate_request
    header = request.headers['Authorization']
    header = header.split(' ').last if header

    begin
      @decoded = JsonWebToken.decode(header)
      @current_user = User.find(@decoded[:user_id])
    rescue ActiveRecord::RecordNotFound => e
      render json: { errors: e.message }, status: :unauthorized
    rescue JWT::DecodeError => e
      render json: { errors: e.message }, status: :unauthorized
    end
  end

  def check_authorization(organization_id)
    puts current_user.email
    puts organization_id
    deny_access unless current_user.has_access?(organization_id)
  end

  def current_user
    @current_user
  end

  def deny_access
    render json: { errors: [I18n.t('errors.unauthorized')] }, status: :forbidden
  end
end
