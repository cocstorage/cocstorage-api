class RemoveNameIndexInStorage < ActiveRecord::Migration[6.0]
  def change
    remove_index :storages, :name
  end
end
