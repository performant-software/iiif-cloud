class AddUserDefinedFieldsToResources < ActiveRecord::Migration[7.0]
  def up
    add_column :resources, :user_defined, :jsonb, default: {}
    add_index :resources, :user_defined, using: :gin
  end

  def down
    remove_index :resources, :user_defined
    remove_column :resources, :user_defined
  end
end
