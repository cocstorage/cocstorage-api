class ChangeContentColumnTypeInNotice < ActiveRecord::Migration[6.0]
  def up
    change_column :notices, :content, :text
  end

  def down
    change_column :notices, :content, :string
  end
end
