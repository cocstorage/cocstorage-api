class AddScrapCodeToStorageBoard < ActiveRecord::Migration[6.0]
  def change
    add_column :storage_boards, :scrap_code, :string
    add_index :storage_boards, :scrap_code, unique: true
  end
end
