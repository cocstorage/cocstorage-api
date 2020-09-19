class CreateStorages < ActiveRecord::Migration[6.0]
  def change
    create_table :storages do |t|
      t.references :storage_category, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :path
      t.string :name
      t.string :description
      t.boolean :is_active, default: true
      t.string :created_ip
      t.string :created_user_agent

      t.timestamps
    end
  end
end
