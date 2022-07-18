class Organization < ApplicationRecord
  # Relationships
  has_many :user_organizations, dependent: :destroy

  # Nested attributes
  accepts_nested_attributes_for :user_organizations, allow_destroy: true

  # Resourceable attributes
  allow_params :name, :location, user_organizations_attributes: [:id, :user_id, :_destroy]
end
