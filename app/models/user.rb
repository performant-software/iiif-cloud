class User < ApplicationRecord
  # Relationships
  has_many :user_organizations, dependent: :destroy

  # Resourceable parameters
  allow_params :api_key

  def has_access?(organization_ids)
    if organization_ids.is_a?(Integer)
      organization_ids = [organization_ids]
    end

    user_organizations.pluck(:organization_id).any? { |id| organization_ids.include?(id) }
  end
end
