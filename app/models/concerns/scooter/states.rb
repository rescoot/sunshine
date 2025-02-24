module Scooter::States
  extend ActiveSupport::Concern

  included do
    # Valid states
    POWER_STATES = %w[ready-to-drive stand-by entering-hibernation hibernation-imminent hibernating].freeze
    SCOOTER_STATES = %w[stand-by parked ready-to-drive shutting-down updating off].freeze
    POWER_MODES = %w[suspending running hibernating suspending-imminent hibernating-imminent booting unknown].freeze
    HIBERNATION_LEVELS = %w[L1 L2 unknown]
    HANDLEBAR_STATES = %w[locked unlocked].freeze
    KICKSTAND_STATES = %w[up down].freeze
    SEATBOX_STATES = %w[closed open].freeze
    BLINKER_STATES = %w[off left right both].freeze

    validates :state, inclusion: { in: POWER_STATES }, if: :state?
    validates :kickstand, inclusion: { in: KICKSTAND_STATES }, allow_nil: true
    validates :seatbox, inclusion: { in: SEATBOX_STATES }, allow_nil: true
    validates :blinkers, inclusion: { in: BLINKER_STATES }, allow_nil: true

    after_update :handle_state_change, if: :saved_change_to_state?
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

  def locked?
    !unlocked?
  end

  def unlocked?
    %w[parked ready-to-drive].include? state
  end

  private

  def handle_state_change(old_state = state_previously_was, new_state = state)
    return if old_state == new_state

    case new_state
    when "ready-to-drive"
      start_trip unless current_trip
    when "hibernating"
      end_trip if current_trip
    end
  end
end
