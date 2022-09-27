class RemoveMetadataFromResources < ActiveRecord::Migration[7.0]
  def up
    remove_column :resources, :metadata
  end

  def down
    add_column :resources, :metadata, :text
  end
end
