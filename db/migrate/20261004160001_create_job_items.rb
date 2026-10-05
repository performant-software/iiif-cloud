class CreateJobItems < ActiveRecord::Migration[8.0]
  def change
    create_table :job_items do |t|
      t.references :job, null: false, foreign_key: true
      t.bigint :resource_id, null: false
      t.string :status, null: false, default: 'pending'
      t.text :error

      t.timestamps
    end

    add_index :job_items, [:job_id, :resource_id], unique: true
  end
end
