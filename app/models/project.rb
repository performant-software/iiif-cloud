class Project < ApplicationRecord
  # Relationships
  belongs_to :organization

  # Resourceable attributes
  allow_params :organization_id, :name, :description, :api_key

  # Callbacks
  before_create :set_bucket_name

  private

  def set_bucket_name
    self.bucket_name = Storage.new.generate_name(self.name)
  end
end
