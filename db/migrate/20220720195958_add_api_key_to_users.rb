class AddApiKeyToUsers < ActiveRecord::Migration[7.0]
  def up
    add_column :users, :api_key, :string
    remove_column :projects, :api_key
  end

  def down
    remove_column :users, :api_key
    add_column :projects, :api_key, :string
  end
end
