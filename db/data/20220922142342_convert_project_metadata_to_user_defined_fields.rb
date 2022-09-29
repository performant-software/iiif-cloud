# frozen_string_literal: true

class ConvertProjectMetadataToUserDefinedFields < ActiveRecord::Migration[7.0]
  def up
    execute <<-SQL.squish
          WITH 
      expand_metadata AS (
        SELECT projects.id AS defineable_id, 'Project' AS defineable_type, json_array_elements(projects.metadata::json) AS field_json
          FROM projects
         WHERE projects.metadata IS NOT NULL
      ),
      extract_field_values AS (
        SELECT defineable_id, 
               defineable_type, 
               'Resource' AS table_name, 
               field_json->>'name' AS column_name, 
               field_json->>'type' AS data_type, 
               (COALESCE(field_json->>'required', 'false'))::boolean AS required, 
               (COALESCE(field_json->>'multiple', 'false'))::boolean AS allow_multiple, 
               ARRAY(SELECT json_array_elements_text(field_json->'options')) AS options
          FROM expand_metadata
      )
      INSERT INTO user_defined_fields_user_defined_fields (defineable_id, defineable_type, table_name, column_name, data_type, required, allow_multiple, options, created_at, updated_at)
      SELECT defineable_id, defineable_type, table_name, column_name, data_type, required, allow_multiple, options, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
        FROM extract_field_values
    SQL

    execute <<-SQL.squish
      UPDATE user_defined_fields_user_defined_fields 
         SET data_type = 'Select' 
       WHERE data_type = 'dropdown'
    SQL

    execute <<-SQL.squish
      UPDATE user_defined_fields_user_defined_fields 
         SET data_type = 'String' 
       WHERE data_type = 'string'
    SQL

    execute <<-SQL.squish
      UPDATE user_defined_fields_user_defined_fields 
         SET data_type = 'Number' 
       WHERE data_type = 'number'
    SQL

    execute <<-SQL.squish
      UPDATE user_defined_fields_user_defined_fields 
         SET data_type = 'Text' 
       WHERE data_type = 'text'
    SQL

    execute <<-SQL.squish
      UPDATE user_defined_fields_user_defined_fields 
         SET data_type = 'Date' 
       WHERE data_type = 'date'
    SQL

    execute <<-SQL.squish
      UPDATE user_defined_fields_user_defined_fields 
         SET data_type = 'Boolean' 
       WHERE data_type = 'checkbox'
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
