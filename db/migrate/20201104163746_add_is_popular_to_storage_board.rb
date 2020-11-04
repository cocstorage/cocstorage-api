class AddIsPopularToStorageBoard < ActiveRecord::Migration[6.0]
  def change
    add_column :storage_boards, :is_popular, :boolean, default: false
  end
end
