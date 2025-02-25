class Telemetry < ApplicationRecord
  belongs_to :scooter

  validates :scooter, presence: true

  # Scopes for querying
  scope :recent, -> { order(created_at: :desc) }
  scope :last_24_hours, -> { where("created_at > ?", 24.hours.ago) }
  scope :with_coordinates, -> { where.not(lat: nil, lng: nil) }
  scope :with_battery_data, -> { where.not(battery0_level: nil) }

  after_create :update_scooter
  after_create :process_trip_state
  after_commit :invalidate_cache

  # Helper method to create from raw telemetry data
  def self.create_from_data!(scooter, data)
    if data["version"] == 2
      create_from_v2_data!(scooter, data)
    else
      create_from_v1_data!(scooter, data)
    end
  end

  private

  def self.create_from_v1_data!(scooter, data)
    create!(
      scooter: scooter,
      state: data["state"],
      kickstand: data["kickstand"],
      seatbox: data["seatbox"],
      blinkers: data["blinkers"],
      speed: data["speed"],
      odometer: data["odometer"],
      motor_voltage: data["motor_voltage"],
      motor_current: data["motor_current"],
      temperature: data["temperature"],
      battery0_level: data["battery0_level"],
      battery1_level: data["battery1_level"],
      battery0_present: data["battery0_present"],
      battery1_present: data["battery1_present"],
      aux_battery_level: data["aux_battery_level"],
      aux_battery_voltage: data["aux_battery_voltage"],
      cbb_battery_level: data["cbb_battery_level"],
      cbb_battery_current: data["cbb_battery_current"],
      lat: data["lat"],
      lng: data["lng"],
      timestamp: data["timestamp"]
    )
  end

  def self.create_from_v2_data!(scooter, data)
    vehicle_state = data["vehicle_state"]
    engine = data["engine"]
    battery0 = data["battery0"]
    battery1 = data["battery1"]
    aux_battery = data["aux_battery"]
    cbb_battery = data["cbb_battery"]
    system = data["system"]
    connectivity = data["connectivity"]
    gps = data["gps"]
    power = data["power"]
    ble = data["ble"]
    keycard = data["keycard"]
    dashboard = data["dashboard"]

    create!(
      scooter: scooter,
      # Vehicle state
      state: vehicle_state["state"],
      main_power: vehicle_state["main_power"],
      handlebar_lock: vehicle_state["handlebar_lock"],
      handlebar_position: vehicle_state["handlebar_position"],
      brake_left: vehicle_state["brake_left"],
      brake_right: vehicle_state["brake_right"],
      kickstand: vehicle_state["kickstand"],
      seatbox: vehicle_state["seatbox"],
      blinker_switch: vehicle_state["blinker_switch"],
      blinkers: vehicle_state["blinker_state"],
      seatbox_button: vehicle_state["seatbox_button"],
      horn_button: vehicle_state["horn_button"],

      # Engine data
      speed: engine["speed"],
      odometer: engine["odometer"],
      motor_voltage: engine["motor_voltage"],
      motor_current: engine["motor_current"],
      temperature: engine["temperature"],
      engine_state: engine["engine_state"],
      kers_state: engine["kers_state"],
      kers_reason_off: engine["kers_reason_off"],
      motor_rpm: engine["motor_rpm"],
      throttle_state: engine["throttle_state"],
      engine_fw_version: engine["engine_fw_version"],

      # Battery 0
      battery0_level: battery0["level"],
      battery0_present: battery0["present"],
      battery0_state: battery0["state"],
      battery0_temp_state: battery0["temp_state"],
      battery0_soh: battery0["soh"],
      battery0_temps: battery0["temps"],
      battery0_cycle_count: battery0["cycle_count"],
      battery0_fw_version: battery0["fw_version"],
      battery0_manufacturing_date: battery0["manufacturing_date"],
      battery0_serial_number: battery0["serial_number"],

      # Battery 1
      battery1_level: battery1["level"],
      battery1_present: battery1["present"],
      battery1_state: battery1["state"],
      battery1_temp_state: battery1["temp_state"],
      battery1_soh: battery1["soh"],
      battery1_temps: battery1["temps"],
      battery1_cycle_count: battery1["cycle_count"],
      battery1_fw_version: battery1["fw_version"],
      battery1_manufacturing_date: battery1["manufacturing_date"],
      battery1_serial_number: battery1["serial_number"],

      # Aux Battery
      aux_battery_level: aux_battery["level"],
      aux_battery_voltage: aux_battery["voltage"],
      aux_battery_charge_status: aux_battery["charge_status"],

      # CBB Battery
      cbb_battery_level: cbb_battery["level"],
      cbb_battery_current: cbb_battery["current"],
      cbb_battery_temperature: cbb_battery["temperature"],
      cbb_battery_soh: cbb_battery["soh"],
      cbb_battery_charge_status: cbb_battery["charge_status"],
      cbb_battery_cell_voltage: cbb_battery["cell_voltage"],
      cbb_battery_cycle_count: cbb_battery["cycle_count"],
      cbb_battery_full_capacity: cbb_battery["full_capacity"],
      cbb_battery_part_number: cbb_battery["part_number"],
      cbb_battery_remaining_capacity: cbb_battery["remaining_capacity"],
      cbb_battery_serial_number: cbb_battery["serial_number"],
      cbb_battery_time_to_empty: cbb_battery["time_to_empty"],
      cbb_battery_time_to_full: cbb_battery["time_to_full"],
      cbb_battery_unique_id: cbb_battery["unique_id"],

      # System
      mdb_version: system["mdb_version"],
      environment: system["environment"],
      nrf_fw_version: system["nrf_fw_version"],
      dbc_version: system["dbc_version"],

      # Connectivity
      modem_state: connectivity["modem_state"],
      internet_status: connectivity["internet_status"],
      cloud_status: connectivity["cloud_status"],
      ip_address: connectivity["ip_address"],
      access_tech: connectivity["access_tech"],
      signal_quality: connectivity["signal_quality"],

      # GPS
      lat: gps["lat"],
      lng: gps["lng"],
      altitude: gps["altitude"],
      gps_speed: gps["gps_speed"],
      course: gps["course"],

      # Power
      power_state: power["power_state"],
      power_mux_input: power["power_mux_input"],
      wakeup_source: power["wakeup_source"],

      # BLE
      ble_mac_address: ble["mac_address"],
      ble_status: ble["status"],

      # Keycard
      keycard_authentication: keycard["authentication"],
      keycard_uid: keycard["uid"],
      keycard_type: keycard["type"],

      # Dashboard
      dashboard_mode: dashboard["mode"],
      dashboard_ready: dashboard["ready"],
      dashboard_serial_number: dashboard["serial_number"],

      # Metadata
      timestamp: data["timestamp"]
    )
  end

  def update_scooter
    scooter.ble_mac = ble_mac_address if ble_mac_address.present?
    scooter.save!
  end

  def invalidate_cache
    TelemetryCacheService.invalidate_cache_for_scooter(scooter_id)
  end

  def process_trip_state
    TelemetryTripProcessor.new(self).process
  rescue => e
    Rails.logger.error "Error processing trip state for telemetry ##{id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
  end
end
