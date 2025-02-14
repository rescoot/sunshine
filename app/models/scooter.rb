class Scooter < ApplicationRecord
  has_many :user_scooters, dependent: :destroy
  has_many :users, through: :user_scooters
  has_many :trips
  has_many :scooter_events
  has_many :telemetries
  has_one :api_token, dependent: :destroy

  has_many :raw_messages, foreign_key: :imei, primary_key: :imei
  validates :imei, uniqueness: true, allow_nil: true

  validates :name, presence: true
  validates :vin, presence: true, uniqueness: true

  include ActionView::RecordIdentifier
  # broadcasts_to ->(scooter) { scooter }

  # Valid states
  POWER_STATES = %w[ready-to-drive stand-by entering-hibernation hibernation-imminent hibernating].freeze
  SCOOTER_STATES = %w[stand-by parked ready-to-drive shutting-down updating off].freeze
  POWER_MODES = %w[suspending running hibernating suspending-imminent hibernating-imminent booting unknown].freeze
  HIBERNATION_LEVELS = %w[L1 L2 unknown]
  HANDLEBAR_STATES = %w[locked unlocked].freeze
  KICKSTAND_STATES = %w[up down].freeze
  SEATBOX_STATES = %w[closed open].freeze
  BLINKER_STATES = %w[off left right both].freeze

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

  validates :state, inclusion: { in: POWER_STATES }, if: :state?
  validates :kickstand, inclusion: { in: KICKSTAND_STATES }, allow_nil: true
  validates :seatbox, inclusion: { in: SEATBOX_STATES }, allow_nil: true
  validates :blinkers, inclusion: { in: BLINKER_STATES }, allow_nil: true

  before_validation :initialize_default_values, on: :create
  after_update :handle_imei_change, if: :saved_change_to_imei?
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

  def friendly_state
    case state
    when "ready-to-drive", "hibernating"
      state
    when "stand-by"
      kickstand == "up" ? "parked" : "stand-by"
    else
      state
    end.titleize
  end

  def ready_to_drive?
    state == "ready-to-drive" && kickstand == "up" && seatbox == "closed"
  end

  def location?
    location.present? && location.created_at >= 12.hours.ago
  end

  def location
    @location ||= telemetries.where.not(lat: 0, lng: 0).order(created_at: :desc).first
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

  def current_trip
    trips&.in_progress&.last
  end

  def start_trip
    return if current_trip

    trips.create!(
      user: owner,
      started_at: Time.current,
      start_lat: lat,
      start_lng: lng,
      start_odometer: odometer
    )
  end

  def end_trip
    trip = current_trip
    return unless trip

    trip.update!(
      ended_at: Time.current,
      end_lat: lat,
      end_lng: lng,
      end_odometer: odometer,
      distance: odometer - trip.start_odometer,
      avg_speed: calculate_average_speed(trip)
    )
  end

  def calculate_average_speed(trip)
    return nil unless trip.started_at && trip.end_odometer && trip.start_odometer

    duration_hours = (Time.current - trip.started_at) / 1.hour
    return nil if duration_hours.zero?

    distance_km = (trip.end_odometer - trip.start_odometer) / 1000.0
    (distance_km / duration_hours).round(1)
  end

  def regenerating?
    telemetry.motor_current < 0
  end

  def telemetry
    telemetries.order(created_at: :desc).first
  end

  def has_token?
    !api_token.nil?
  end

  def generate_config_with_token(token)
    {
      "scooter" => {
        "identifier" => vin,
        "token" => token
      },
      "environment" => Rails.env.to_s,
      "mqtt" => {
        "broker_url" => "ssl://mqtt.sunshine.rescoot.org:8883",
        "ca_cert" => "/etc/keys/sunshine-mqtt-ca.crt",
        "keepalive" => "180s"
      },
      "redis_url" => "redis://localhost:6379",
      "telemetry" => {
        "intervals" => {
          "driving" => "1s",
          "standby" => "5m",
          "standby_no_battery" => "8h",
          "hibernate" => "24h"
        }
      }
    }
  end

  def estimated_range
    # scooter gets approx 35-40km per full battery
    [ 0.0, battery0_level, battery1_level ].compact.sum * 40.0 / 100.0
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
      broadcast_update_to "online_status", is_online? ? "Online" : "Offline"
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

  def handle_state_change(old_state, new_state)
    return if old_state == new_state

    case new_state
    when "ready-to-drive"
      start_trip(scooter) unless scooter.current_trip
    when "hibernating"
      end_trip(scooter) if scooter.current_trip
    end
  end

  private

  def initialize_default_values
    self.state ||= "stand-by"
    self.kickstand ||= "down"
    self.seatbox ||= "closed"
    self.blinkers ||= "off"
    self.battery0_level ||= 0
    self.battery1_level ||= 0
    self.aux_battery_level ||= 0
    self.cbb_battery_level ||= 0
  end

  def handle_imei_change
    MqttAuthService.setup_imei_auth(self) if imei.present?
  end
end
