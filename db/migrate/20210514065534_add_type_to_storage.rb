class AddTypeToStorage < ActiveRecord::Migration[6.0]
  def change
    add_column :storages, :type, :integer, default: 0
  end
end
