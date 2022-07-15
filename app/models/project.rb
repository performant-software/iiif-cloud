class Project < ApplicationRecord
  # Includes
  include Attachable

  # Relationships
  belongs_to :organization

  # Resourceable attributes
  allow_params :organization_id, :name, :description, :api_key, :avatar, :metadata

  # ActiveStorage
  has_one_attached :avatar

  # Validations
  validate :validate_metadata

  private

  def validate_metadata
    return unless self.metadata?

    JSON.parse(self.metadata).each do |item|
      errors.add(:metadata, I18n.t('errors.project.metadata.name_empty')) unless item['name'].present?
      errors.add(:metadata, I18n.t('errors.project.metadata.type_empty')) unless item['type'].present?

      next unless item['type'] == 'dropdown'

      errors.add(:metadata, I18n.t('errors.project.metadata.options_empty')) unless item['options'].present?
      errors.add(:metadata, I18n.t('errors.project.metadata.options_duplicate')) unless item['options'].size == item['options'].uniq.size
    end
  end
end
