class AddManifestToResources < ActiveRecord::Migration[7.0]
  def up
    add_column :resources, :manifest, :text
  end

  def down
    remove_column :resources, :manifest
  end
end
