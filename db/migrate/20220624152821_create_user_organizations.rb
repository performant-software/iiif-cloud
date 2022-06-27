class CreateUserOrganizations < ActiveRecord::Migration[7.0]
  def up
    create_table :user_organizations do |t|
      t.references :user, null: false, foreign_key: true, index: true
      t.references :organization, null: false, foreign_key: true, index: true

      t.timestamps
    end
  end

  def down
    drop_table :user_organizations
  end
end
