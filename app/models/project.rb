class Project < ApplicationRecord
  # Relationships
  belongs_to :organization

  # Resourceable attributes
  allow_params :organization_id, :uid, :name, :description, :api_key
end
