class AddV2FieldsToTelemetry < ActiveRecord::Migration[8.0]
  def change
    change_table :telemetries do |t|
      # Vehicle state fields
      t.string :main_power
      t.string :handlebar_lock
      t.string :handlebar_position
      t.string :brake_left
      t.string :brake_right
      t.string :blinker_switch
      t.string :seatbox_button
      t.string :horn_button

      # Engine fields
      t.string :engine_state
      t.string :kers_state
      t.string :kers_reason_off
      t.integer :motor_rpm
      t.string :throttle_state
      t.string :engine_fw_version

      # Battery fields
      t.string :battery0_state
      t.string :battery0_temp_state
      t.integer :battery0_soh
      t.json :battery0_temps
      t.integer :battery0_cycle_count
      t.string :battery0_fw_version
      t.string :battery0_manufacturing_date
      t.string :battery0_serial_number

      t.string :battery1_state
      t.string :battery1_temp_state
      t.integer :battery1_soh
      t.json :battery1_temps
      t.integer :battery1_cycle_count
      t.string :battery1_fw_version
      t.string :battery1_manufacturing_date
      t.string :battery1_serial_number

      t.string :aux_battery_charge_status

      t.integer :cbb_battery_temperature
      t.integer :cbb_battery_soh
      t.string :cbb_battery_charge_status
      t.integer :cbb_battery_cell_voltage
      t.integer :cbb_battery_cycle_count
      t.integer :cbb_battery_full_capacity
      t.string :cbb_battery_part_number
      t.integer :cbb_battery_remaining_capacity
      t.string :cbb_battery_serial_number
      t.integer :cbb_battery_time_to_empty
      t.integer :cbb_battery_time_to_full
      t.string :cbb_battery_unique_id

      # System fields
      t.string :environment
      t.string :dbc_version
      t.string :mdb_version
      t.string :nrf_fw_version

      # Connectivity fields
      t.string :modem_state
      t.string :access_tech
      t.integer :signal_quality
      t.string :internet_status
      t.string :ip_address
      t.string :cloud_status

      # GPS additional fields
      t.decimal :altitude, precision: 10, scale: 6
      t.decimal :gps_speed, precision: 10, scale: 2
      t.decimal :course, precision: 10, scale: 2

      # Power fields
      t.string :power_state
      t.string :power_mux_input
      t.string :wakeup_source

      # BLE fields
      t.string :ble_mac_address
      t.string :ble_status

      # Keycard fields
      t.string :keycard_authentication
      t.string :keycard_uid
      t.string :keycard_type

      # Dashboard fields
      t.string :dashboard_mode
      t.boolean :dashboard_ready
      t.string :dashboard_serial_number
    end
  end
end
