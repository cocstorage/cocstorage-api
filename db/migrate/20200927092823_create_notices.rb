class CreateNotices < ActiveRecord::Migration[6.0]
  def change
    create_table :notices do |t|
      t.references :user, null: false, foreign_key: true
      t.string :subject
      t.string :content
      t.string :description
      t.integer :view_count, default: 0
      t.boolean :is_draft, default: true
      t.boolean :is_active, default: true
      t.string :created_ip
      t.string :created_user_agent

      t.timestamps
    end
  end
end
