class AddDefaultValueToIsActiveInStorages < ActiveRecord::Migration[6.0]
  def up
    change_column :storages, :is_active, :boolean, default: true
  end
  def down
    change_column :storages, :is_active, :boolean
  end
end
