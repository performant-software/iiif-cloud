class AddMetadataToProjects < ActiveRecord::Migration[7.0]
  def up
    add_column :projects, :metadata, :text
  end

  def down
    remove_column :projects, :metadata
  end
end
