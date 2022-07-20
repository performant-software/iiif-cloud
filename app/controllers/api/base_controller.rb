class Api::BaseController < Api::ResourceController
  # Actions
  before_action :authenticate_request

  protected

  def check_authorization(organization_id)
    deny_access unless current_user.has_access?(organization_id)
  end

  def current_user
    @current_user
  end

  def deny_access
    render json: { errors: [I18n.t('errors.unauthorized')] }, status: :forbidden
  end

  private

  def authenticate_request
    header = request.headers['Authorization']
    header = header.split(' ').last if header
    api_key = request.headers['X-API-KEY']

    begin
      if header
        @decoded = JsonWebToken.decode(header)
        @current_user = User.find(@decoded[:user_id])
      elsif api_key
        @current_user = User.find_by_api_key(api_key)
      else
        render json: { errors: I18n.t('errors.unauthenticated') }, status: :unauthorized
      end
    rescue ActiveRecord::RecordNotFound => e
      render json: { errors: e.message }, status: :unauthorized
    rescue JWT::DecodeError => e
      render json: { errors: e.message }, status: :unauthorized
    end
  end
end
