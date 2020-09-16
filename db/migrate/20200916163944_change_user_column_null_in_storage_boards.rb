class ChangeUserColumnNullInStorageBoards < ActiveRecord::Migration[6.0]
  def up
    change_column_null :storage_boards, :user_id, :true
  end

  def down
    change_column_null :storage_boards, :user_id, :false
  end
end
