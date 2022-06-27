class User < ApplicationRecord
  # JWT
  has_secure_password

  # Relationships
  has_many :user_organizations, dependent: :destroy

  # Nested attributes
  accepts_nested_attributes_for :user_organizations, allow_destroy: true

  # Resourceable parameters
  allow_params :name, :email, :admin, :password, :password_confirmation, user_organizations_attributes: [:id, :organization_id, :_destroy]
end
