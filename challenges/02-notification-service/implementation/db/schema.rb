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

ActiveRecord::Schema[8.0].define(version: 2025_12_15_142915) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "notifications", force: :cascade do |t|
    t.string "notification_id", limit: 255, null: false
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
