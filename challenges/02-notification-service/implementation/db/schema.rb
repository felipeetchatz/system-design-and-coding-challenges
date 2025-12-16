# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_12_15_173602) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "notification_preferences", force: :cascade do |t|
    t.string "user_id", limit: 255, null: false
    t.string "channel", limit: 50, null: false
    t.string "notification_type", limit: 100, null: false
    t.boolean "enabled", default: true
    t.time "quiet_hours_start"
    t.time "quiet_hours_end"
    t.string "timezone", limit: 50
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "channel", "notification_type"], name: "index_notification_preferences_on_user_channel_type", unique: true
    t.index ["user_id"], name: "idx_preferences_user_id"
  end

  create_table "notification_templates", force: :cascade do |t|
    t.string "template_id", limit: 255, null: false
    t.string "channel", limit: 50, null: false
    t.string "subject", limit: 500
    t.text "body", null: false
    t.jsonb "variables"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["channel"], name: "idx_templates_channel"
    t.index ["template_id"], name: "idx_templates_template_id", unique: true
  end

  create_table "notifications", force: :cascade do |t|
    t.uuid "notification_id", null: false
    t.string "user_id", limit: 255, null: false
    t.string "channel", limit: 50, null: false
    t.string "template_id", limit: 255, null: false
    t.jsonb "variables"
    t.string "status", limit: 50, null: false
    t.string "priority", limit: 20, default: "normal"
    t.datetime "scheduled_at", precision: nil
    t.datetime "queued_at", precision: nil, null: false
    t.datetime "sent_at", precision: nil
    t.datetime "delivered_at", precision: nil
    t.datetime "failed_at", precision: nil
    t.integer "retry_count", default: 0
    t.integer "max_retries", default: 3
    t.text "error_message"
    t.string "external_id", limit: 255
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["channel"], name: "idx_notifications_channel"
    t.index ["created_at"], name: "idx_notifications_created_at"
    t.index ["notification_id"], name: "index_notifications_on_notification_id", unique: true
    t.index ["scheduled_at"], name: "idx_notifications_scheduled_at", where: "(scheduled_at IS NOT NULL)"
    t.index ["status"], name: "idx_notifications_status"
    t.index ["user_id"], name: "idx_notifications_user_id"
  end
end
