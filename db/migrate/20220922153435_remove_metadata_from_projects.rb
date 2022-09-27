class RemoveMetadataFromProjects < ActiveRecord::Migration[7.0]
  def up
    remove_column :projects, :metadata
  end

  def down
    add_column :projects, :metadata, :text
  end
end
