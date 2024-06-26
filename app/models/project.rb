class Project < ApplicationRecord
  # Includes
  include Attachable
  include Identifiable
  include UserDefinedFields::Defineable

  # Relationships
  belongs_to :organization
  has_many :resources, dependent: :destroy

  # Resourceable attributes
  allow_params :organization_id, :name, :description, :avatar

  # ActiveStorage
  has_one_attached :avatar
end
