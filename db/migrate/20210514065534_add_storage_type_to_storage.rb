class AddStorageTypeToStorage < ActiveRecord::Migration[6.0]
  def change
    add_column :storages, :storage_type, :integer, default: 0
  end
end
