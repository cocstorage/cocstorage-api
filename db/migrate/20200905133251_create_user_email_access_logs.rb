class CreateUserEmailAccessLogs < ActiveRecord::Migration[6.0]
  def change
    create_table :user_email_access_logs do |t|
      t.references :user, null: false, foreign_key: true
      t.string :access_uuid
      t.string :access_expired_at
      t.string :created_ip

      t.timestamps
    end
  end
end
