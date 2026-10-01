module Public
  module Authenticateable
    extend ActiveSupport::Concern

    included do
      protected

      attr_reader :current_user

      def authenticate_request
        api_key = request.headers['X-API-KEY']
        render_unauthorized I18n.t('errors.unauthenticated') and return unless api_key.present?

        begin
          @current_user = User.find_by_api_key(api_key)
          render_unauthorized I18n.t('errors.unauthenticated') and return unless @current_user
        rescue ActiveRecord::RecordNotFound => e
          render_unauthorized e.message
        end
      end

      # For actions that write to storage (R2), an API key alone isn't enough - only admins may.
      def require_admin
        render_forbidden(I18n.t('errors.unauthorized')) unless current_user&.admin?
      end

      private

      def render_unauthorized(errors)
        render json: { errors: errors }, status: :unauthorized
      end

      def render_forbidden(errors)
        render json: { errors: errors }, status: :forbidden
      end
    end
  end
end