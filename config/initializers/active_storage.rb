require_relative '../../app/controllers/concerns/public/authenticateable'

Rails.application.config.to_prepare do
  ActiveStorage::DirectUploadsController.class_eval do
    # Includes
    include Public::Authenticateable

    # Actions
    before_action :authenticate_request
  end
end