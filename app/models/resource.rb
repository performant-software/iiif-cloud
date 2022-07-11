class Resource < ApplicationRecord
  # Includes
  include Attachable

  # Relationships
  belongs_to :project

  # Resourceable parameters
  allow_params :project_id, :name, :metadata, :content

  # ActiveStorage
  has_one_attached :content
end
