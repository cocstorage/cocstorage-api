class CreateStorageUserRoles < ActiveRecord::Migration[6.0]
  def change
    create_table :storage_user_roles do |t|
      t.references :storage, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :role
      t.string :created_ip
      t.string :created_user_agent

      t.timestamps
    end
  end
end
