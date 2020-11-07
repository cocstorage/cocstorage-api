class ChangeDescriptionColumnTypeInNotice < ActiveRecord::Migration[6.0]
  def up
    change_column :notices, :description, :text
  end

  def down
    change_column :notices, :description, :string
  end
end
