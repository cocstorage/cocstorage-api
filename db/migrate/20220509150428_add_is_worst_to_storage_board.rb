class AddIsWorstToStorageBoard < ActiveRecord::Migration[6.0]
  def change
    add_column :storage_boards, :is_worst, :boolean, default: false
  end
end
