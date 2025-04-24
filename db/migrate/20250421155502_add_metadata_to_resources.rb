class AddMetadataToResources < ActiveRecord::Migration[7.0]
  def change
    add_column :resources, :metadata, :jsonb, default: {}
  end
end
