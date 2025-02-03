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

ActiveRecord::Schema[8.0].define(version: 2025_02_03_223505) do
  create_table "api_tokens", force: :cascade do |t|
    t.integer "scooter_id"
    t.string "token_digest"
    t.datetime "last_used_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.string "scope", null: false
    t.string "name"
    t.index ["scooter_id"], name: "index_api_tokens_on_scooter_id"
    t.index ["scope"], name: "index_api_tokens_on_scope"
    t.index ["token_digest"], name: "index_api_tokens_on_token_digest", unique: true
    t.index ["user_id"], name: "index_api_tokens_on_user_id"
  end

  create_table "raw_messages", force: :cascade do |t|
    t.string "imei", null: false
    t.string "topic", null: false
    t.json "payload"
    t.datetime "received_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "scooter_id"
    t.index ["imei"], name: "index_raw_messages_on_imei"
    t.index ["scooter_id"], name: "index_raw_messages_on_scooter_id"
  end

  create_table "scooters", force: :cascade do |t|
    t.string "name"
    t.string "vin"
    t.string "state"
    t.string "kickstand"
    t.string "seatbox"
    t.string "blinkers"
    t.decimal "speed"
    t.decimal "odometer"
    t.decimal "battery0_level"
    t.decimal "battery1_level"
    t.decimal "aux_battery_level"
    t.decimal "cbb_battery_level"
    t.decimal "lat"
    t.decimal "lng"
    t.datetime "last_seen_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "color"
    t.string "imei"
    t.index ["imei"], name: "index_scooters_on_imei", unique: true
    t.index ["vin"], name: "index_scooters_on_vin", unique: true
  end

  create_table "telemetries", force: :cascade do |t|
    t.integer "scooter_id", null: false
    t.string "state"
    t.string "kickstand"
    t.string "seatbox"
    t.string "blinkers"
    t.decimal "speed", precision: 10, scale: 2
    t.decimal "odometer", precision: 10, scale: 2
    t.decimal "motor_voltage", precision: 10, scale: 2
    t.decimal "motor_current", precision: 10, scale: 2
    t.decimal "temperature", precision: 10, scale: 2
    t.decimal "battery0_level", precision: 5, scale: 2
    t.decimal "battery1_level", precision: 5, scale: 2
    t.boolean "battery0_present"
    t.boolean "battery1_present"
    t.decimal "aux_battery_level", precision: 5, scale: 2
    t.decimal "aux_battery_voltage", precision: 10, scale: 2
    t.decimal "cbb_battery_level", precision: 5, scale: 2
    t.decimal "cbb_battery_current", precision: 10, scale: 2
    t.decimal "lat", precision: 10, scale: 6
    t.decimal "lng", precision: 10, scale: 6
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "timestamp"
    t.index ["scooter_id", "created_at"], name: "index_telemetries_on_scooter_id_and_created_at"
    t.index ["scooter_id"], name: "index_telemetries_on_scooter_id"
  end

  create_table "trips", force: :cascade do |t|
    t.integer "scooter_id", null: false
    t.integer "user_id", null: false
    t.datetime "started_at"
    t.decimal "start_lat"
    t.decimal "start_lng"
    t.datetime "ended_at"
    t.decimal "end_lat"
    t.decimal "end_lng"
    t.decimal "distance"
    t.decimal "avg_speed"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ended_at"], name: "index_trips_on_ended_at"
    t.index ["scooter_id", "started_at"], name: "index_trips_on_scooter_id_and_started_at"
    t.index ["scooter_id"], name: "index_trips_on_scooter_id"
    t.index ["user_id", "started_at"], name: "index_trips_on_user_id_and_started_at"
    t.index ["user_id"], name: "index_trips_on_user_id"
  end

  create_table "unu_requests", force: :cascade do |t|
    t.string "method"
    t.string "path"
    t.string "remote_ip"
    t.text "headers"
    t.text "body"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "user_scooters", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "scooter_id", null: false
    t.string "role", default: "user"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["scooter_id"], name: "index_user_scooters_on_scooter_id"
    t.index ["user_id", "role"], name: "index_user_scooters_on_user_id_and_role"
    t.index ["user_id", "scooter_id"], name: "index_user_scooters_on_user_id_and_scooter_id", unique: true
    t.index ["user_id"], name: "index_user_scooters_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "telegram_chat_id"
    t.boolean "is_admin", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "api_tokens", "scooters"
  add_foreign_key "api_tokens", "users"
  add_foreign_key "raw_messages", "scooters"
  add_foreign_key "telemetries", "scooters"
  add_foreign_key "trips", "scooters"
  add_foreign_key "trips", "users"
  add_foreign_key "user_scooters", "scooters"
  add_foreign_key "user_scooters", "users"
end
