class AddPdfSupportToResources < ActiveRecord::Migration[8.0]
  def change
    # Add pages_count column to track PDF page count
    add_column :resources, :pages_count, :integer

    # Add index for querying resources with multi-page conversions
    add_index :resources, :pages_count
  end
end
