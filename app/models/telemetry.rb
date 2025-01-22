class Telemetry < ApplicationRecord
  belongs_to :scooter

  validates :scooter, presence: true

  # Scopes for querying
  scope :recent, -> { order(created_at: :desc) }
  scope :last_24_hours, -> { where("created_at > ?", 24.hours.ago) }

  # Helper method to create from raw telemetry data
  def self.create_from_data!(scooter, data)
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
end
