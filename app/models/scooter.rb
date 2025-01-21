class Scooter < ApplicationRecord
  has_many :user_scooters, dependent: :destroy
  has_many :users, through: :user_scooters
  has_many :trips
  has_one :api_token, dependent: :destroy

  validates :name, presence: true
  validates :vin, presence: true, uniqueness: true

  # Valid states
  STATES = %w[locked unlocked hibernating].freeze
  KICKSTAND_STATES = %w[up down].freeze
  SEATBOX_STATES = %w[closed open].freeze
  BLINKER_STATES = %w[off left right hazard].freeze

  validates :state, inclusion: { in: STATES }, allow_nil: true
  validates :kickstand, inclusion: { in: KICKSTAND_STATES }, allow_nil: true
  validates :seatbox, inclusion: { in: SEATBOX_STATES }, allow_nil: true
  validates :blinkers, inclusion: { in: BLINKER_STATES }, allow_nil: true

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
    last_seen_at && last_seen_at > 5.minutes.ago
  end

  def locked?
    state == "locked"
  end

  def unlocked?
    state == "unlocked"
  end
end
