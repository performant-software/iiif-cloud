module Public
  module Authenticateable
    extend ActiveSupport::Concern

    included do
      protected

      def authenticate_request
        api_key = request.headers['X-API-KEY']
        render_unauthorized I18n.t('errors.unauthenticated') and return unless api_key.present?

        begin
          @current_user = User.find_by_api_key(api_key)
        rescue ActiveRecord::RecordNotFound => e
          render_unauthorized e.message
        end
      end

      private

      def render_unauthorized(errors)
        render json: { errors: errors }, status: :unauthorized
      end
    end
  end
end