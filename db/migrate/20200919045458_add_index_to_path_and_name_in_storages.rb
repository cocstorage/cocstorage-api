class AddIndexToPathAndNameInStorages < ActiveRecord::Migration[6.0]
  def change
    add_index :storages, :path, unique: true
    add_index :storages, :name, unique: true
  end
end
