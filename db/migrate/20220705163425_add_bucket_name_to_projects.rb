class AddBucketNameToProjects < ActiveRecord::Migration[7.0]
  def up
    add_column :projects, :bucket_name, :string
  end

  def down
    remove_column :projects, :bucket_name
  end
end
