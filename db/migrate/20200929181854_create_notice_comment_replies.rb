class CreateNoticeCommentReplies < ActiveRecord::Migration[6.0]
  def change
    create_table :notice_comment_replies do |t|
      t.references :notice_comment, null: false, foreign_key: true
      t.references :user, null: true, foreign_key: true
      t.string :nickname
      t.string :password
      t.text :content
      t.integer :thumb_up, default: 0
      t.integer :thumb_down, default: 0
      t.boolean :is_active, default: true
      t.boolean :is_member, default: false
      t.string :created_ip
      t.string :created_user_agent

      t.timestamps
    end
  end
end
