class Scooter < ApplicationRecord
  has_many :user_scooters, dependent: :destroy
  has_many :users, through: :user_scooters
  has_many :trips
  has_many :telemetries
  has_one :api_token, dependent: :destroy

  include ActionView::RecordIdentifier
  # broadcasts_to ->(scooter) { scooter }

  validates :name, presence: true
  validates :vin, presence: true, uniqueness: true

  # Valid states
  STATES = %w[stand-by ready-to-drive off parked hibernating locked].freeze
  KICKSTAND_STATES = %w[up down].freeze
  SEATBOX_STATES = %w[closed open].freeze
  BLINKER_STATES = %w[off left right both].freeze

  # color indexes from the unustasis app
  COLOR_MAPPING = {
    "black" => { index: 0, hex: "#000000" },
    "white" => { index: 1, hex: "#FFFFFF" },
    "green" => { index: 2, hex: "#1B5E20" },  # green.shade900
    "gray" => { index: 3, hex: "#9E9E9E" },   # grey primary
    "orange" => { index: 4, hex: "#FF7043" },  # deepOrange.shade400
    "red" => { index: 5, hex: "#F44336" },     # red primary
    "blue" => { index: 6, hex: "#2196F3" },    # blue primary
    "eclipse" => { index: 7, hex: "#424242" },  # grey.shade800
    "idioteque" => { index: 8, hex: "#80CBC4" }, # teal.shade200
    "hover" => { index: 9, hex: "#03A9F4" }     # lightBlue primary
  }.freeze

  validates :state, inclusion: { in: STATES }, allow_nil: true
  validates :kickstand, inclusion: { in: KICKSTAND_STATES }, allow_nil: true
  validates :seatbox, inclusion: { in: SEATBOX_STATES }, allow_nil: true
  validates :blinkers, inclusion: { in: BLINKER_STATES }, allow_nil: true

  after_update_commit :broadcast_updates

  def owner
    user_scooters.find_by(role: "owner")&.user
  end

  def update_location(lat:, lng:)
    update(
      lat: lat,
      lng: lng,
      last_seen_at: Time.current
    )
  end

  def online?
    true || last_seen_at && last_seen_at > 5.minutes.ago
  end

  def locked?
    !unlocked?
  end

  def unlocked?
    %w[parked ready-to-drive].include? state
  end

  def color_value
    COLOR_MAPPING[color][:index] if color
  end

  def color_hex
    COLOR_MAPPING[color][:hex] if color
  end

  def scooter_image_path(type = "base")
    if color
      "scooter/#{type}_#{color_value}.webp"
    else
      "scooter/disconnected.webp"
    end
  end

  def battery_image_path(level)
    case level
    when 0..25 then "battery/batt_25.webp"
    when 26..50 then "battery/batt_50.webp"
    when 51..75 then "battery/batt_75.webp"
    else "battery/batt_full.webp"
    end
  end

  def regenerating?
    telemetry.motor_current < 0
  end

  def telemetry
    telemetries.order(created_at: :desc).first
  end

  private

  def broadcast_updates
    broadcast_state_update
    broadcast_batteries_update
    broadcast_controls_update if saved_change_to_state? || saved_change_to_blinkers?

    broadcast_replace_to self,
      target: "scooter_#{id}_visual",
      partial: "scooters/visual_status",
      locals: { scooter: self } if saved_change_to_state? || saved_change_to_blinkers?

    if saved_change_to_blinkers? || saved_change_to_state?
      broadcast_update_later_to(
        self,
        target: "scooter_#{id}_blinkers",
        partial: "scooters/blinkers",
        locals: { scooter: self }
      )
    end

    if saved_change_to_speed?
      broadcast_update_later_to(
        self,
        target: "scooter_#{id}_speed",
        partial: "scooters/speed",
        locals: { scooter: self }
      )
    end
  end

  def broadcast_state_update
    # Broadcast individual state changes
    if saved_change_to_state?
      broadcast_update_to "state", state
    end
    if saved_change_to_kickstand?
      broadcast_update_to "kickstand", kickstand
    end
    if saved_change_to_seatbox?
      broadcast_update_to "seatbox", seatbox
    end
    if saved_change_to_blinkers?
      broadcast_update_to "blinkers", blinkers
    end
    if saved_change_to_last_seen_at?
      broadcast_update_to "last_seen", last_seen_text
      broadcast_update_to "online_status", online? ? "Online" : "Offline"
    end
  end

  def broadcast_batteries_update
    if saved_change_to_battery0_level?
      broadcast_update_to "battery0", number_to_percentage(battery0_level, precision: 1)
    end
    if saved_change_to_battery1_level?
      broadcast_update_to "battery1", number_to_percentage(battery1_level, precision: 1)
    end
    if saved_change_to_aux_battery_level?
      broadcast_update_to "aux_battery", number_to_percentage(aux_battery_level, precision: 1)
    end
    if saved_change_to_cbb_battery_level?
      broadcast_update_to "cbb_battery", number_to_percentage(cbb_battery_level, precision: 1)
    end
  end

  def broadcast_controls_update
    broadcast_update_to "controls",
      ApplicationController.render(partial: "scooters/controls", locals: { scooter: self })
  end

  def broadcast_update_to(target, content)
    broadcast_update_later_to(
      target: "#{self.class.name.underscore}_#{id}", # _#{target}",
      html: content
    )
  end

  def last_seen_text
    last_seen_at ? "#{ApplicationController.helpers.time_ago_in_words(last_seen_at)} ago" : "Never"
  end

  def number_to_percentage(number, options = {})
    ApplicationController.helpers.number_to_percentage(number, options)
  end
end
