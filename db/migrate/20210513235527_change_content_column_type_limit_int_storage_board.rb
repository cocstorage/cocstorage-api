class ChangeContentColumnTypeLimitIntStorageBoard < ActiveRecord::Migration[6.0]
  def up
    change_column :storage_boards, :content, :text, :limit => 4294967295
  end

  def down
    change_column :storage_boards, :content, :text
  end
end
