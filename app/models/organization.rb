class Organization < ApplicationRecord
  # Relationships
  has_many :user_organizations, dependent: :destroy

  # Resourceable attributes
  allow_params :name, :location
end
