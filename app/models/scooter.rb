class Scooter < ApplicationRecord
  include Broadcastable
  include States
  include BatteryManagement

  has_many :user_scooters, dependent: :destroy
  has_many :users, through: :user_scooters
  has_many :trips, dependent: :destroy
  has_many :scooter_events, dependent: :destroy
  has_many :telemetries
  has_many :scooter_commands, dependent: :destroy
  has_one :api_token, dependent: :destroy
  belongs_to :last_unlock_user, class_name: "User", optional: true

  has_many :raw_messages, foreign_key: :imei, primary_key: :imei
  validates :imei, uniqueness: true, allow_nil: true

  validates :name, presence: true
  validates :vin, presence: true, uniqueness: true

  before_validation :initialize_default_values, on: :create
  after_update :handle_imei_change, if: :saved_change_to_imei?

  delegate :current_trip, :start_trip, :end_trip, to: :trip_management_service

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

  def location?
    location.present? && location.created_at >= 12.hours.ago
  end

  def location
    @location ||= telemetries.where.not(lat: 0, lng: 0).order(created_at: :desc).first
  rescue => e
    Rails.logger.error "Error getting location: #{e.message}"
    nil
  end

  def telemetry
    telemetries.recent.first
  rescue => e
    Rails.logger.error "Error getting telemetry: #{e.message}"
    nil
  end

  def has_token?
    !api_token.nil?
  end

  def determine_trip_user(timestamp = nil)
    # If a timestamp is provided, find the most recent unlock command before that timestamp
    # Otherwise, use the current time
    time_limit = timestamp || Time.current

    # Find the most recent unlock command within the last 30 minutes
    last_unlock_command = scooter_commands
      .where(command: "unlock")
      .where("created_at <= ?", time_limit)
      .where("created_at >= ?", time_limit - 30.minutes)
      .order(created_at: :desc)
      .first

    if last_unlock_command
      # Use the user who sent the unlock command
      last_unlock_command.user
    elsif last_unlock_user_id && last_unlocked_at && last_unlocked_at >= time_limit - 30.minutes
      # Fall back to the last_unlock_user if available (for backward compatibility)
      last_unlock_user
    else
      # Otherwise fall back to the owner
      owner
    end
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
          "driving" => "5s",
          "standby" => "10m",
          "standby_no_battery" => "4h",
          "hibernate" => "24h"
        }
      }
    }
  end

  private

  def initialize_default_values
    self.state ||= "stand-by"
    self.kickstand ||= "down"
    self.seatbox ||= "closed"
    self.blinkers ||= "off"
    self.odometer ||= 0
    self.battery0_level ||= 0
    self.battery1_level ||= 0
    self.aux_battery_level ||= 0
    self.cbb_battery_level ||= 0
  end

  def handle_imei_change
    MqttAuthService.setup_imei_auth(self) if imei.present?
  end

  def trip_management_service
    @trip_management_service ||= TripManagementService.new(self)
  end
end
