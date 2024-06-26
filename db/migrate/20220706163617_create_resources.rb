class CreateResources < ActiveRecord::Migration[7.0]
  def up
    create_table :resources do |t|
      t.references :project, null: false, foreign_key: true, index: true
      t.string :name
      t.text :exif
      t.text :metadata

      t.timestamps
    end
  end

  def down
    drop_table :resources
  end
end
