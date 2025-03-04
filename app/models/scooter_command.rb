class ScooterCommand < ApplicationRecord
  belongs_to :scooter
  belongs_to :user

  # Command statuses
  STATUSES = %w[pending sent succeeded failed expired].freeze

  # Default TTL values for different commands (in seconds)
  COMMAND_TTL = {
    "unlock" => 10,          # 10 seconds
    "open_seatbox" => 10,    # 10 seconds
    "lock" => 3600,          # 1 hour
    "blinkers" => 10,        # 10 seconds
    "honk" => 10,            # 10 seconds
    "locate" => 60,          # 1 minute
    "ping" => 300,           # 5 minutes
    "get_state" => 86400,    # 24 hours
    "play_sound" => 300,     # 5 minutes
    "alarm" => 300,          # 5 minutes
    "update" => 86400,       # 24 hours
    "redis" => 3600,         # 1 hour
    "shell" => 3600          # 1 hour
  }.freeze

  # Commands that should not be queued for safety reasons
  NON_QUEUEABLE_COMMANDS = %w[unlock open_seatbox].freeze

  before_create :set_request_id
  before_create :set_queueable_and_ttl
  before_create :set_expires_at

  scope :pending, -> { where(status: "pending") }
  scope :queued, -> { where(queued: true) }
  scope :not_expired, -> { where("expires_at > ?", Time.current) }

  def mark_as_sent
    update(status: "sent", processed_at: Time.current)
  end

  def mark_as_succeeded
    update(status: "succeeded", processed_at: Time.current)
  end

  def mark_as_failed
    update(status: "failed", processed_at: Time.current)
  end

  def expired?
    expires_at.present? && expires_at <= Time.current
  end

  private

  def set_request_id
    self.request_id ||= SecureRandom.uuid
  end

  def set_queueable_and_ttl
    # Set queueable based on command type
    self.queueable = !NON_QUEUEABLE_COMMANDS.include?(command)

    # Set TTL based on command type
    self.queue_ttl = COMMAND_TTL[command] || 3600 # Default to 1 hour
  end

  def set_expires_at
    self.expires_at = Time.current + queue_ttl.seconds if queued?
  end
end
