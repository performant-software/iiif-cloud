class Project < ApplicationRecord
  # Includes
  include Attachable

  # Relationships
  belongs_to :organization

  # Resourceable attributes
  allow_params :organization_id, :name, :description, :api_key, :avatar

  # ActiveStorage
  has_one_attached :avatar
end
