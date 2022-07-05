class User < ApplicationRecord
  # JWT
  has_secure_password

  # Relationships
  has_many :user_organizations, dependent: :destroy

  # Nested attributes
  accepts_nested_attributes_for :user_organizations, allow_destroy: true

  # Resourceable parameters
  allow_params :name, :email, :admin, :password, :password_confirmation, user_organizations_attributes: [:id, :organization_id, :_destroy]

  # Validations
  validates :user_organizations, presence: true, unless: :admin?

  def has_access?(organization_ids)
    if organization_ids.is_a?(String)
      organization_ids = [organization_ids]
    end

    user_organizations.pluck(:organization_id).any? { |id| organization_ids.include?(id) }
  end
end
