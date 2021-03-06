# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160413012112) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "blog_posts", force: :cascade do |t|
    t.string   "title"
    t.text     "body"
    t.text     "tags"
    t.integer  "hits",                  default: 0
    t.boolean  "public",                default: true
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "slug"
    t.datetime "deleted_at"
    t.boolean  "subscriber_alert_sent", default: false
  end

  add_index "blog_posts", ["deleted_at"], name: "index_blog_posts_on_deleted_at", using: :btree

  create_table "blog_subscriptions", force: :cascade do |t|
    t.string   "email"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "unsub_key"
    t.datetime "deleted_at"
  end

  add_index "blog_subscriptions", ["deleted_at"], name: "index_blog_subscriptions_on_deleted_at", using: :btree

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",   default: 0, null: false
    t.integer  "attempts",   default: 0, null: false
    t.text     "handler",                null: false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree

  create_table "feedbacks", force: :cascade do |t|
    t.string   "name"
    t.string   "email"
    t.text     "message"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "folder_shares", force: :cascade do |t|
    t.integer  "folder_id"
    t.boolean  "is_all_topics",   default: false
    t.text     "specific_topics"
    t.integer  "recipient_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "sender_id"
    t.string   "recipient_email"
    t.datetime "deleted_at"
  end

  add_index "folder_shares", ["deleted_at"], name: "index_folder_shares_on_deleted_at", using: :btree

  create_table "folders", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.boolean  "perm_deleted", default: false
    t.datetime "restored_at"
  end

  add_index "folders", ["deleted_at"], name: "index_folders_on_deleted_at", using: :btree

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.string   "slug",                      null: false
    t.integer  "sluggable_id",              null: false
    t.string   "sluggable_type", limit: 50
    t.string   "scope"
    t.datetime "created_at"
  end

  add_index "friendly_id_slugs", ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true, using: :btree
  add_index "friendly_id_slugs", ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type", using: :btree
  add_index "friendly_id_slugs", ["sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_id", using: :btree
  add_index "friendly_id_slugs", ["sluggable_type"], name: "index_friendly_id_slugs_on_sluggable_type", using: :btree

  create_table "jots", force: :cascade do |t|
    t.integer  "folder_id"
    t.integer  "topic_id"
    t.integer  "user_id"
    t.boolean  "is_flagged",      default: false
    t.integer  "order"
    t.text     "content"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "break_from_top",  default: false
    t.string   "jot_type",        default: "standard"
    t.datetime "deleted_at"
    t.string   "tagged_email_id"
    t.string   "color"
    t.boolean  "perm_deleted",    default: false
    t.datetime "restored_at"
  end

  add_index "jots", ["deleted_at"], name: "index_jots_on_deleted_at", using: :btree

  create_table "support_ticket_messages", force: :cascade do |t|
    t.integer  "support_ticket_id"
    t.integer  "user_id"
    t.text     "message"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "message_type"
  end

  create_table "support_tickets", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "unique_id"
    t.string   "subject"
    t.string   "status",              default: "new"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "slug"
    t.datetime "last_answered_at"
    t.datetime "author_last_read_at"
  end

  create_table "topic_shares", force: :cascade do |t|
    t.integer  "sender_id"
    t.string   "recipient_email"
    t.integer  "folder_id"
    t.integer  "topic_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "recipient_id"
    t.datetime "deleted_at"
  end

  add_index "topic_shares", ["deleted_at"], name: "index_topic_shares_on_deleted_at", using: :btree

  create_table "topics", force: :cascade do |t|
    t.integer  "folder_id"
    t.integer  "user_id"
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.boolean  "perm_deleted", default: false
    t.datetime "restored_at"
  end

  add_index "topics", ["deleted_at"], name: "index_topics_on_deleted_at", using: :btree

  create_table "uploads", force: :cascade do |t|
    t.integer  "user_id",                             null: false
    t.string   "direct_upload_url",                   null: false
    t.string   "upload_file_name"
    t.string   "upload_content_type"
    t.integer  "upload_file_size"
    t.datetime "upload_updated_at"
    t.boolean  "processed",           default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "width",               default: 0
    t.integer  "height",              default: 0
    t.integer  "jot_id"
  end

  add_index "uploads", ["processed"], name: "index_uploads_on_processed", using: :btree
  add_index "uploads", ["user_id"], name: "index_uploads_on_user_id", using: :btree

  create_table "user_meta_data", force: :cascade do |t|
    t.integer  "upload_size_this_month", default: 0
    t.datetime "upload_limit_resets_at"
    t.integer  "user_id"
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
    t.boolean  "saw_last_news_flash",    default: true
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",                   default: "",    null: false
    t.string   "encrypted_password",      default: "",    null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",           default: 0,     null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "display_name"
    t.boolean  "is_viewing_key_controls", default: true
    t.string   "auth_provider"
    t.string   "auth_provider_uid"
    t.string   "auth_token"
    t.datetime "auth_token_expiration"
    t.string   "auth_refresh_token"
    t.boolean  "is_terms_agreed",         default: false
    t.text     "notifications_seen"
    t.boolean  "receives_email",          default: true
    t.string   "timezone"
    t.boolean  "saw_intro",               default: false
    t.text     "preferences"
    t.boolean  "admin",                   default: false
    t.string   "photo_url"
    t.boolean  "photo_uploaded_manually", default: false
    t.datetime "last_seen_at"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

end
