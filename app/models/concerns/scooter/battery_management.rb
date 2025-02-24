module Scooter::BatteryManagement
  extend ActiveSupport::Concern

  # color indexes from the unustasis app
  COLOR_MAPPING = {
    "black" => { index: 0, hex: "#0F0F0F" },
    "white" => { index: 1, hex: "#F9F9F9" },
    "pine" => { index: 2, hex: "#255242" },
    "stone" => { index: 3, hex: "#A4A4A4" },
    "coral" => { index: 4, hex: "#B86057" },
    "red" => { index: 5, hex: "#D4220F" },
    "blue" => { index: 6, hex: "#0F214F" },
    "eclipse" => { index: 7, hex: "#494949" },
    "idioteque" => { index: 8, hex: "#80CBC4" },
    "hover" => { index: 9, hex: "#03A9F4" }
  }.freeze

  def color_id
    color_value
  end

  def color_value
    COLOR_MAPPING[color][:index] if color
  end

  def color_hex
    COLOR_MAPPING[color][:hex] if color
  end

  def scooter_image_path(type = "side")
    if color
      "scooter/#{type}_#{color_value}.png"
    else
      "scooter/disconnected.png"
    end
  end

  def battery_image_path(level)
    case level
    when 0 then "battery/batt_empty.webp"
    when ..25 then "battery/batt_25.webp"
    when 26..50 then "battery/batt_50.webp"
    when 51..75 then "battery/batt_75.webp"
    else "battery/batt_full.webp"
    end
  end

  def estimated_range
    # scooter gets approx 35-40km per full battery
    [ 0.0, battery0_level, battery1_level ].compact.sum * 40.0 / 100.0
  end

  def regenerating?
    telemetry.motor_current < 0
  end
end
