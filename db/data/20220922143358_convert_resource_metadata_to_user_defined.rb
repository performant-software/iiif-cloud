# frozen_string_literal: true

class ConvertResourceMetadataToUserDefined < ActiveRecord::Migration[7.0]
  def up
    execute <<-SQL.squish
      UPDATE resources
         SET user_defined = metadata::jsonb
       WHERE metadata IS NOT NULL
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
