class AddContentJsonToStorageBoard < ActiveRecord::Migration[6.0]
  def change
    add_column :storage_boards, :content_json, :text
  end
end
