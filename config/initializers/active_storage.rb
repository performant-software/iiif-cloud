require_relative '../../app/controllers/concerns/public/authenticateable'

Rails.application.config.to_prepare do
  # Custom storage key generation based on the "storage_key" attribute in metadata
  ActiveStorage::Blob.class_eval do
    def key
      self[:key] ||= generate_key
    end

    private

    def generate_key
      object_prefix = self.metadata[:storage_key]
      object_key = self.class.generate_unique_secure_token(length: self.class::MINIMUM_TOKEN_LENGTH)

      [object_prefix, object_key].reject(&:blank?).join('/')
    end
  end

  # Authentication for direct uploads
  ActiveStorage::DirectUploadsController.class_eval do
    # Includes
    include Public::Authenticateable

    # Actions
    before_action :authenticate_request
  end
end