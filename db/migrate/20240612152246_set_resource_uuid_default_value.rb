class SetResourceUuidDefaultValue < ActiveRecord::Migration[7.0]
  def change
    change_column :resources, :uuid, :uuid, default: 'gen_random_uuid()', using: 'uuid::uuid'
  end
end
