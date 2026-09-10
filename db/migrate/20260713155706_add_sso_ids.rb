class AddSsoIds < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :sso_id, :string
    add_column :organizations, :sso_id, :string
  end
end
