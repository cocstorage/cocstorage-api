class RemoveScrapCodeIndexInStorageBoard < ActiveRecord::Migration[6.0]
  def change
    remove_index :storage_boards, :scrap_code
    add_index :storage_boards, :scrap_code
  end
end
