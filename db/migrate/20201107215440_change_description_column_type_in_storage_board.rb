class ChangeDescriptionColumnTypeInStorageBoard < ActiveRecord::Migration[6.0]
  def up
    change_column :storage_boards, :description, :text
  end

  def down
    change_column :storage_user_roles, :description, :string
  end
end
