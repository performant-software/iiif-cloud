class CreateProjects < ActiveRecord::Migration[7.0]
  def change
    create_table :projects do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :uid
      t.string :name
      t.text :description
      t.string :api_key

      t.timestamps
    end
  end
end
