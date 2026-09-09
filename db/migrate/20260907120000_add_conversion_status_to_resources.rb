class AddConversionStatusToResources < ActiveRecord::Migration[8.0]
  def change
    add_column :resources, :conversion_status, :string, null: false, default: 'pending'
    add_column :resources, :conversion_error, :text
    add_column :resources, :conversion_failed_at, :datetime
  end
end