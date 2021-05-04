class AddSourceCodeToStorageBoard < ActiveRecord::Migration[6.0]
  def change
    add_column :storage_boards, :source_code, :string
  end
end
