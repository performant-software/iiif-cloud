class AddStorageKeyToResources < ActiveRecord::Migration[8.0]
  def change
    add_column :resources, :storage_key, :string
  end
end
