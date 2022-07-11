class CreateProjects < ActiveRecord::Migration[7.0]
  def up
    create_table :projects do |t|
      t.references :organization, null: false, foreign_key: true, index: true
      t.string :uid
      t.string :name
      t.text :description
      t.string :api_key

      t.timestamps
    end
  end

  def down
    drop_table :projects
  end
end
