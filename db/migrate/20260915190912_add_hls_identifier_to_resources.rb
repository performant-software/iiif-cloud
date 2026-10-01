class AddHlsIdentifierToResources < ActiveRecord::Migration[8.0]
  def change
    add_column :resources, :hls_identifier, :string
  end
end
