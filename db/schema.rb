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

ActiveRecord::Schema.define(version: 20150829062516) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "folders", force: true do |t|
    t.integer  "user_id"
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  add_index "folders", ["deleted_at"], name: "index_folders_on_deleted_at", using: :btree

  create_table "jots", force: true do |t|
    t.integer  "folder_id"
    t.integer  "topic_id"
    t.integer  "user_id"
    t.boolean  "is_flagged",     default: false
    t.integer  "order"
    t.text     "content"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "break_from_top", default: false
    t.string   "jot_type",       default: "standard"
    t.datetime "deleted_at"
  end

  add_index "jots", ["deleted_at"], name: "index_jots_on_deleted_at", using: :btree

  create_table "preferences", force: true do |t|
    t.integer  "user_id"
    t.string   "display_name"
    t.string   "color_scheme"
    t.boolean  "is_viewing_key_controls", default: true
    t.boolean  "notify_upcoming_event"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "shares", force: true do |t|
    t.integer  "folder_id"
    t.boolean  "is_all_topics"
    t.text     "specific_topics"
    t.integer  "recipient_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "owner_id"
  end

  create_table "topics", force: true do |t|
    t.integer  "folder_id"
    t.integer  "user_id"
    t.string   "title"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  add_index "topics", ["deleted_at"], name: "index_topics_on_deleted_at", using: :btree

  create_table "users", force: true do |t|
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
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

end
