class AddAdminToUsers < ActiveRecord::Migration[7.0]
  def up
    add_column :users, :admin, :boolean, default: false
  end

  def down
    remove_column :users, :admin
  end
end
