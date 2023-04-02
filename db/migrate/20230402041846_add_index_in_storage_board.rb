class AddIndexInStorageBoard < ActiveRecord::Migration[6.0]
  def change
    add_index :storage_boards, [:is_draft], name: 'index_storage_boards_on_opt1'
    add_index :storage_boards, [:is_active], name: 'index_storage_boards_on_opt2'
    add_index :storage_boards, [:is_draft, :is_active], name: 'index_storage_boards_on_opt3'
    add_index :storage_boards, [:is_active, :is_draft], name: 'index_storage_boards_on_opt4'
    add_index :storage_boards, [:is_draft, :is_active, :is_worst, :is_popular], name: 'index_storage_boards_on_opt5'
    add_index :storage_boards, [:is_draft, :is_active, :is_popular, :is_worst], name: 'index_storage_boards_on_opt6'
    add_index :storage_boards, [:is_active, :is_draft, :is_worst, :is_popular], name: 'index_storage_boards_on_opt7'
    add_index :storage_boards, [:is_active, :is_draft, :is_popular, :is_worst], name: 'index_storage_boards_on_opt8'
    add_index :storage_boards, [:is_worst, :is_popular], name: 'index_storage_boards_on_opt9'
    add_index :storage_boards, [:is_popular, :is_worst], name: 'index_storage_boards_on_opt10'
  end
end
