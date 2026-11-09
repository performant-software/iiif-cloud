class CreateJobs < ActiveRecord::Migration[8.0]
  def change
    create_table :jobs do |t|
      t.string :uuid, null: false
      t.string :status, null: false, default: 'pending'
      t.integer :total_count, null: false, default: 0
      t.integer :completed_count, null: false, default: 0
      t.integer :failed_count, null: false, default: 0

      t.timestamps
    end

    add_index :jobs, :uuid, unique: true
  end
end
