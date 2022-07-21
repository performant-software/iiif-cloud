class AddUidToResources < ActiveRecord::Migration[7.0]
  def up
    add_column :resources, :uuid, :string
  end

  def down
    remove_column :resources, :uuid
  end
end
