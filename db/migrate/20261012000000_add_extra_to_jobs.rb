class AddExtraToJobs < ActiveRecord::Migration[8.0]
  def change
    add_column :jobs, :extra, :jsonb, default: {}
  end
end
