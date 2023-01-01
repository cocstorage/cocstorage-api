class AddContentJsonToNotice < ActiveRecord::Migration[6.0]
  def change
    add_column :notices, :content_json, :text
  end
end
