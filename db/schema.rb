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

ActiveRecord::Schema[8.0].define(version: 2024_12_27_213129) do
  create_table "api_tokens", force: :cascade do |t|
    t.integer "scooter_id", null: false
    t.string "token_digest"
    t.datetime "last_used_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["scooter_id"], name: "index_api_tokens_on_scooter_id"
    t.index ["token_digest"], name: "index_api_tokens_on_token_digest", unique: true
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
    t.index ["vin"], name: "index_scooters_on_vin", unique: true
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
    t.index ["scooter_id"], name: "index_trips_on_scooter_id"
    t.index ["user_id"], name: "index_trips_on_user_id"
  end

  create_table "user_scooters", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "scooter_id", null: false
    t.string "role", default: "user"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["scooter_id"], name: "index_user_scooters_on_scooter_id"
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
  add_foreign_key "trips", "scooters"
  add_foreign_key "trips", "users"
  add_foreign_key "user_scooters", "scooters"
  add_foreign_key "user_scooters", "users"
end
