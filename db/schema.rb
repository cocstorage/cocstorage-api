# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2023_04_02_041846) do

  create_table "active_storage_attachments", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.string "service_name", default: "1", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "issue_keyword_contents", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "issue_keyword_id", null: false
    t.string "url"
    t.string "source"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "title"
    t.string "description"
    t.integer "content_type", default: 0
    t.index ["issue_keyword_id"], name: "index_issue_keyword_contents_on_issue_keyword_id"
  end

  create_table "issue_keyword_ranks", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "date"
    t.json "ranks"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "issue_keywords", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "keyword"
    t.string "source"
    t.string "original"
    t.integer "count"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["keyword"], name: "index_issue_keywords_on_keyword", unique: true
  end

  create_table "jwt_denylist", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "jti", null: false
    t.datetime "exp", null: false
    t.index ["jti"], name: "index_jwt_denylist_on_jti"
  end

  create_table "jwt_denylists", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "notice_comment_replies", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "notice_comment_id", null: false
    t.bigint "user_id"
    t.string "nickname"
    t.string "password"
    t.text "content"
    t.integer "thumb_up", default: 0
    t.integer "thumb_down", default: 0
    t.boolean "is_active", default: true
    t.boolean "is_member", default: false
    t.string "created_ip"
    t.string "created_user_agent"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["notice_comment_id"], name: "index_notice_comment_replies_on_notice_comment_id"
    t.index ["user_id"], name: "index_notice_comment_replies_on_user_id"
  end

  create_table "notice_comments", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "notice_id", null: false
    t.bigint "user_id"
    t.string "nickname"
    t.string "password"
    t.text "content"
    t.integer "thumb_up", default: 0
    t.integer "thumb_down", default: 0
    t.boolean "is_active", default: true
    t.boolean "is_member", default: false
    t.string "created_ip"
    t.string "created_user_agent"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["notice_id"], name: "index_notice_comments_on_notice_id"
    t.index ["user_id"], name: "index_notice_comments_on_user_id"
  end

  create_table "notices", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "subject"
    t.text "content"
    t.text "description"
    t.integer "view_count", default: 0
    t.boolean "is_draft", default: true
    t.boolean "is_active", default: true
    t.string "created_ip"
    t.string "created_user_agent"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.text "content_json"
    t.index ["user_id"], name: "index_notices_on_user_id"
  end

  create_table "storage_board_comment_replies", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "storage_board_comment_id", null: false
    t.bigint "user_id"
    t.string "nickname"
    t.string "password"
    t.text "content"
    t.integer "thumb_up", default: 0
    t.integer "thumb_down", default: 0
    t.boolean "is_active", default: true
    t.boolean "is_member", default: false
    t.string "created_ip"
    t.string "created_user_agent"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["storage_board_comment_id"], name: "index_storage_board_comment_replies_on_storage_board_comment_id"
    t.index ["user_id"], name: "index_storage_board_comment_replies_on_user_id"
  end

  create_table "storage_board_comments", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "storage_board_id", null: false
    t.bigint "user_id"
    t.string "nickname"
    t.string "password"
    t.text "content"
    t.integer "thumb_up", default: 0
    t.integer "thumb_down", default: 0
    t.boolean "is_active", default: true
    t.boolean "is_member", default: false
    t.string "created_ip"
    t.string "created_user_agent"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["storage_board_id"], name: "index_storage_board_comments_on_storage_board_id"
    t.index ["user_id"], name: "index_storage_board_comments_on_user_id"
  end

  create_table "storage_board_recommend_logs", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "storage_board_id", null: false
    t.bigint "user_id"
    t.integer "log_type"
    t.string "created_ip"
    t.string "created_user_agent"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["storage_board_id"], name: "index_storage_board_recommend_logs_on_storage_board_id"
    t.index ["user_id"], name: "index_storage_board_recommend_logs_on_user_id"
  end

  create_table "storage_boards", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "storage_id", null: false
    t.bigint "user_id"
    t.string "nickname"
    t.string "password"
    t.string "subject"
    t.text "content", size: :long
    t.text "description"
    t.integer "view_count", default: 0
    t.integer "thumb_up", default: 0
    t.integer "thumb_down", default: 0
    t.boolean "has_image", default: false
    t.boolean "has_video", default: false
    t.boolean "is_draft", default: true
    t.boolean "is_active", default: true
    t.boolean "is_member", default: false
    t.string "created_ip"
    t.string "created_user_agent"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "is_popular", default: false
    t.string "scrap_code"
    t.string "source_code"
    t.boolean "is_worst", default: false
    t.text "content_json"
    t.index ["is_active", "is_draft", "is_popular", "is_worst"], name: "index_storage_boards_on_opt8"
    t.index ["is_active", "is_draft", "is_worst", "is_popular"], name: "index_storage_boards_on_opt7"
    t.index ["is_active", "is_draft"], name: "index_storage_boards_on_opt4"
    t.index ["is_active"], name: "index_storage_boards_on_is_active"
    t.index ["is_active"], name: "index_storage_boards_on_opt2"
    t.index ["is_draft", "is_active", "is_popular", "is_worst"], name: "index_storage_boards_on_opt6"
    t.index ["is_draft", "is_active", "is_worst", "is_popular"], name: "index_storage_boards_on_opt5"
    t.index ["is_draft", "is_active"], name: "index_storage_boards_on_is_draft_and_is_active"
    t.index ["is_draft", "is_active"], name: "index_storage_boards_on_opt3"
    t.index ["is_draft"], name: "index_storage_boards_on_is_draft"
    t.index ["is_draft"], name: "index_storage_boards_on_opt1"
    t.index ["is_popular", "is_worst"], name: "index_storage_boards_on_opt10"
    t.index ["is_worst", "is_popular"], name: "index_storage_boards_on_opt9"
    t.index ["scrap_code"], name: "index_storage_boards_on_scrap_code"
    t.index ["storage_id"], name: "index_storage_boards_on_storage_id"
    t.index ["user_id"], name: "index_storage_boards_on_user_id"
  end

  create_table "storage_categories", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name"
    t.string "code"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "storage_tests", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "storage_user_roles", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "storage_id", null: false
    t.bigint "user_id", null: false
    t.integer "role"
    t.string "created_ip"
    t.string "created_user_agent"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["storage_id"], name: "index_storage_user_roles_on_storage_id"
    t.index ["user_id"], name: "index_storage_user_roles_on_user_id"
  end

  create_table "storages", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "storage_category_id", null: false
    t.bigint "user_id"
    t.string "path"
    t.string "name"
    t.string "description"
    t.boolean "is_active", default: true
    t.string "created_ip"
    t.string "created_user_agent"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "code"
    t.integer "storage_type", default: 0
    t.bigint "issue_keyword_id"
    t.index ["issue_keyword_id"], name: "index_storages_on_issue_keyword_id"
    t.index ["path"], name: "index_storages_on_path", unique: true
    t.index ["storage_category_id"], name: "index_storages_on_storage_category_id"
    t.index ["user_id"], name: "index_storages_on_user_id"
  end

  create_table "user_email_access_logs", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "access_uuid"
    t.string "access_expired_at"
    t.string "created_ip"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["user_id"], name: "index_user_email_access_logs_on_user_id"
  end

  create_table "users", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", default: "", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "nickname", default: "", null: false
    t.integer "point", default: 0, null: false
    t.boolean "is_authenticated", default: false, null: false
    t.boolean "is_active", default: true, null: false
    t.integer "role", default: 0, null: false
    t.string "created_ip", default: "", null: false
    t.datetime "withdrawaled_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["nickname"], name: "index_users_on_nickname", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "issue_keyword_contents", "issue_keywords"
  add_foreign_key "notice_comment_replies", "notice_comments"
  add_foreign_key "notice_comment_replies", "users"
  add_foreign_key "notice_comments", "notices"
  add_foreign_key "notice_comments", "users"
  add_foreign_key "notices", "users"
  add_foreign_key "storage_board_comment_replies", "storage_board_comments"
  add_foreign_key "storage_board_comment_replies", "users"
  add_foreign_key "storage_board_comments", "storage_boards"
  add_foreign_key "storage_board_comments", "users"
  add_foreign_key "storage_board_recommend_logs", "storage_boards"
  add_foreign_key "storage_board_recommend_logs", "users"
  add_foreign_key "storage_boards", "storages"
  add_foreign_key "storage_boards", "users"
  add_foreign_key "storage_user_roles", "storages"
  add_foreign_key "storage_user_roles", "users"
  add_foreign_key "storages", "issue_keywords"
  add_foreign_key "storages", "storage_categories"
  add_foreign_key "storages", "users"
  add_foreign_key "user_email_access_logs", "users"
end
