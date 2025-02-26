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

ActiveRecord::Schema[8.0].define(version: 2025_02_27_003002) do
  create_table "achievement_definitions", force: :cascade do |t|
    t.string "name", null: false
    t.text "description", null: false
    t.string "achievement_type", null: false
    t.float "threshold", null: false
    t.string "icon", null: false
    t.integer "points", default: 10
    t.string "badge_color", default: "blue"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "secret", default: false, null: false
    t.index ["achievement_type"], name: "index_achievement_definitions_on_achievement_type"
    t.index ["name"], name: "index_achievement_definitions_on_name", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

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

  create_table "feature_flags", force: :cascade do |t|
    t.string "key", null: false
    t.string "name", null: false
    t.text "description"
    t.boolean "default_enabled", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_feature_flags_on_key", unique: true
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

  create_table "scooter_events", force: :cascade do |t|
    t.integer "scooter_id", null: false
    t.integer "event_type", null: false
    t.json "data", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["scooter_id", "created_at"], name: "index_scooter_events_on_scooter_id_and_created_at"
    t.index ["scooter_id", "event_type"], name: "index_scooter_events_on_scooter_id_and_event_type"
    t.index ["scooter_id"], name: "index_scooter_events_on_scooter_id"
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
    t.boolean "is_online", default: false, null: false
    t.string "ble_mac"
    t.json "device_ids"
    t.index ["imei"], name: "index_scooters_on_imei", unique: true
    t.index ["is_online"], name: "index_scooters_on_is_online"
    t.index ["last_seen_at"], name: "index_scooters_on_last_seen_at"
    t.index ["lat", "lng"], name: "index_scooters_on_coordinates", where: "lat IS NOT NULL AND lng IS NOT NULL"
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
    t.string "main_power"
    t.string "handlebar_lock"
    t.string "handlebar_position"
    t.string "brake_left"
    t.string "brake_right"
    t.string "blinker_switch"
    t.string "seatbox_button"
    t.string "horn_button"
    t.string "engine_state"
    t.string "kers_state"
    t.string "kers_reason_off"
    t.integer "motor_rpm"
    t.string "throttle_state"
    t.string "engine_fw_version"
    t.string "battery0_state"
    t.string "battery0_temp_state"
    t.integer "battery0_soh"
    t.json "battery0_temps"
    t.integer "battery0_cycle_count"
    t.string "battery0_fw_version"
    t.string "battery0_manufacturing_date"
    t.string "battery0_serial_number"
    t.string "battery1_state"
    t.string "battery1_temp_state"
    t.integer "battery1_soh"
    t.json "battery1_temps"
    t.integer "battery1_cycle_count"
    t.string "battery1_fw_version"
    t.string "battery1_manufacturing_date"
    t.string "battery1_serial_number"
    t.string "aux_battery_charge_status"
    t.integer "cbb_battery_temperature"
    t.integer "cbb_battery_soh"
    t.string "cbb_battery_charge_status"
    t.integer "cbb_battery_cell_voltage"
    t.integer "cbb_battery_cycle_count"
    t.integer "cbb_battery_full_capacity"
    t.string "cbb_battery_part_number"
    t.integer "cbb_battery_remaining_capacity"
    t.string "cbb_battery_serial_number"
    t.integer "cbb_battery_time_to_empty"
    t.integer "cbb_battery_time_to_full"
    t.string "cbb_battery_unique_id"
    t.string "environment"
    t.string "dbc_version"
    t.string "mdb_version"
    t.string "nrf_fw_version"
    t.string "modem_state"
    t.string "access_tech"
    t.integer "signal_quality"
    t.string "internet_status"
    t.string "ip_address"
    t.string "cloud_status"
    t.decimal "altitude", precision: 10, scale: 6
    t.decimal "gps_speed", precision: 10, scale: 2
    t.decimal "course", precision: 10, scale: 2
    t.string "power_state"
    t.string "power_mux_input"
    t.string "wakeup_source"
    t.string "ble_mac_address"
    t.string "ble_status"
    t.string "keycard_authentication"
    t.string "keycard_uid"
    t.string "keycard_type"
    t.string "dashboard_mode"
    t.boolean "dashboard_ready"
    t.string "dashboard_serial_number"
    t.index ["scooter_id", "battery0_level", "battery1_level"], name: "index_telemetries_on_scooter_id_and_battery_levels"
    t.index ["scooter_id", "created_at"], name: "index_telemetries_on_scooter_id_and_created_at"
    t.index ["scooter_id", "lat", "lng"], name: "index_telemetries_on_scooter_id_and_coordinates", where: "lat IS NOT NULL AND lng IS NOT NULL"
    t.index ["scooter_id", "odometer"], name: "index_telemetries_on_scooter_id_and_odometer"
    t.index ["scooter_id"], name: "index_telemetries_on_scooter_id"
  end

  create_table "trip_segments", force: :cascade do |t|
    t.integer "trip_id", null: false
    t.integer "start_telemetry_id", null: false
    t.integer "end_telemetry_id", null: false
    t.float "start_lat"
    t.float "start_lng"
    t.float "end_lat"
    t.float "end_lng"
    t.integer "distance"
    t.integer "segment_order"
    t.string "segment_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "speed"
    t.index ["end_telemetry_id"], name: "index_trip_segments_on_end_telemetry_id"
    t.index ["start_telemetry_id"], name: "index_trip_segments_on_start_telemetry_id"
    t.index ["trip_id", "segment_order"], name: "index_trip_segments_on_trip_id_and_segment_order"
    t.index ["trip_id"], name: "index_trip_segments_on_trip_id"
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
    t.integer "start_odometer"
    t.integer "end_odometer"
    t.integer "start_telemetry_id"
    t.integer "end_telemetry_id"
    t.integer "start_gps_distance", default: 0
    t.integer "end_gps_distance", default: 0
    t.index ["end_telemetry_id"], name: "index_trips_on_end_telemetry_id"
    t.index ["ended_at"], name: "index_trips_on_ended_at"
    t.index ["scooter_id", "distance"], name: "index_trips_on_scooter_id_and_distance"
    t.index ["scooter_id", "started_at"], name: "index_trips_on_scooter_id_and_started_at"
    t.index ["scooter_id"], name: "index_trips_on_scooter_id"
    t.index ["start_telemetry_id"], name: "index_trips_on_start_telemetry_id"
    t.index ["started_at", "ended_at"], name: "index_trips_on_started_at_and_ended_at"
    t.index ["user_id", "distance"], name: "index_trips_on_user_id_and_distance"
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

  create_table "user_achievements", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "achievement_definition_id", null: false
    t.datetime "earned_at"
    t.float "progress", default: 0.0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["achievement_definition_id"], name: "index_user_achievements_on_achievement_definition_id"
    t.index ["earned_at"], name: "index_user_achievements_on_earned_at"
    t.index ["user_id", "achievement_definition_id"], name: "idx_on_user_id_achievement_definition_id_ebd1e08e89", unique: true
    t.index ["user_id", "earned_at"], name: "index_user_achievements_on_user_id_and_earned_at"
    t.index ["user_id"], name: "index_user_achievements_on_user_id"
  end

  create_table "user_feature_flags", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "feature_flag_id", null: false
    t.boolean "enabled", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["feature_flag_id"], name: "index_user_feature_flags_on_feature_flag_id"
    t.index ["user_id", "feature_flag_id"], name: "index_user_feature_flags_on_user_id_and_feature_flag_id", unique: true
    t.index ["user_id"], name: "index_user_feature_flags_on_user_id"
  end

  create_table "user_preferences", force: :cascade do |t|
    t.integer "user_id", null: false
    t.boolean "leaderboard_opt_in", default: false
    t.string "leaderboard_display_name"
    t.boolean "receive_achievement_notifications", default: true
    t.json "notification_settings", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "leaderboard_opt_in"], name: "index_user_preferences_on_user_id_and_leaderboard_opt_in"
    t.index ["user_id"], name: "index_user_preferences_on_user_id"
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
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.string "otp_auth_secret"
    t.string "otp_recovery_secret"
    t.boolean "otp_enabled", default: false, null: false
    t.boolean "otp_mandatory", default: false, null: false
    t.datetime "otp_enabled_on"
    t.integer "otp_failed_attempts", default: 0, null: false
    t.integer "otp_recovery_counter", default: 0, null: false
    t.string "otp_persistence_seed"
    t.string "otp_session_challenge"
    t.datetime "otp_challenge_expires"
    t.string "locale"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["otp_challenge_expires"], name: "index_users_on_otp_challenge_expires"
    t.index ["otp_session_challenge"], name: "index_users_on_otp_session_challenge", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "vin_lookups", force: :cascade do |t|
    t.string "vin", null: false
    t.json "decode_result"
    t.boolean "successful", default: false
    t.string "error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "lookup_count", default: 0, null: false
    t.index ["created_at"], name: "index_vin_lookups_on_created_at"
    t.index ["lookup_count"], name: "index_vin_lookups_on_lookup_count"
    t.index ["vin"], name: "index_vin_lookups_on_vin", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "api_tokens", "scooters"
  add_foreign_key "api_tokens", "users"
  add_foreign_key "raw_messages", "scooters"
  add_foreign_key "scooter_events", "scooters"
  add_foreign_key "telemetries", "scooters"
  add_foreign_key "trip_segments", "telemetries", column: "end_telemetry_id"
  add_foreign_key "trip_segments", "telemetries", column: "start_telemetry_id"
  add_foreign_key "trip_segments", "trips"
  add_foreign_key "trips", "scooters"
  add_foreign_key "trips", "telemetries", column: "end_telemetry_id"
  add_foreign_key "trips", "telemetries", column: "start_telemetry_id"
  add_foreign_key "trips", "users"
  add_foreign_key "user_achievements", "achievement_definitions"
  add_foreign_key "user_achievements", "users"
  add_foreign_key "user_feature_flags", "feature_flags"
  add_foreign_key "user_feature_flags", "users"
  add_foreign_key "user_preferences", "users"
  add_foreign_key "user_scooters", "scooters"
  add_foreign_key "user_scooters", "users"
end
