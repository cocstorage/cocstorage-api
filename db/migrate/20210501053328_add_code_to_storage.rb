class AddCodeToStorage < ActiveRecord::Migration[6.0]
  def change
    add_column :storages, :code, :string
  end
end
