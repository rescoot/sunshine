class Api::V1::ScooterSerializer < ActiveModel::Serializer
  attributes :id, :name, :vin, :color, :state, :online,
             :kickstand, :seatbox, :blinkers, :speed, :odometer,
             :batteries, :location, :last_seen_at

  def online
    object.online?
  end

  def batteries
    telemetry = object.telemetry
    {
      battery0: {
        present: object.battery0_level.present?,
        level: object.battery0_level,
        voltage: telemetry&.motor_voltage
      },
      battery1: {
        present: object.battery1_level.present?,
        level: object.battery1_level,
        voltage: telemetry&.motor_voltage
      },
      aux: {
        present: object.aux_battery_level.present?,
        level: object.aux_battery_level,
        voltage: telemetry&.aux_battery_voltage
      },
      cbb: {
        present: object.cbb_battery_level.present?,
        level: object.cbb_battery_level,
        current: telemetry&.cbb_battery_current
      }
    }
  end

  def location
    {
      lat: object.lat,
      lng: object.lng
    }
  end
end
