module Identifiable
  extend ActiveSupport::Concern

  included do
    # Callbacks
    before_create :set_uuid

    private

    def set_uuid
      self.uuid = SecureRandom.uuid
    end
  end
end
