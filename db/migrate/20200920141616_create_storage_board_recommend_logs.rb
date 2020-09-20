class CreateStorageBoardRecommendLogs < ActiveRecord::Migration[6.0]
  def change
    create_table :storage_board_recommend_logs do |t|
      t.references :storage_board, null: false, foreign_key: true
      t.references :user, null: true, foreign_key: true
      t.integer :log_type
      t.string :created_ip
      t.string :created_user_agent

      t.timestamps
    end
  end
end
