class ChangeDefaultValueIsActiveInUsersAndStorageBoards < ActiveRecord::Migration[6.0]
  def change
    change_column_default(:users, :is_active, from: false, to: true)
    change_column_default(:storage_boards, :is_active, from: false, to: true)
  end
end
