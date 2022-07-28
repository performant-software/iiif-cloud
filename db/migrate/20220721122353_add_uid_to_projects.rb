class AddUidToProjects < ActiveRecord::Migration[7.0]
  def up
    remove_column :projects, :uid
    add_column :projects, :uuid, :string
  end

  def down
    add_column :projects, :uid, :string
    remove_column :projects, :uuid
  end
end
