class CreateStorageBoards < ActiveRecord::Migration[6.0]
  def change
    create_table :storage_boards do |t|
      t.references :storage, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :nickname
      t.string :password
      t.string :subject
      t.text :content
      t.text :description
      t.integer :view_count, default: 0
      t.integer :thumb_up, default: 0
      t.integer :thumb_down, default: 0
      t.boolean :has_image, default: false
      t.boolean :has_video, default: false
      t.boolean :is_draft, default: true
      t.boolean :is_active, default: false
      t.boolean :is_member, default: false
      t.string :created_ip
      t.string :created_user_agent

      t.timestamps
    end
  end
end
