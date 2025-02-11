class ScooterEvent < ApplicationRecord
  belongs_to :scooter

  enum :event_type, {
    connect: 0,
    disconnect: 1,
    state_change: 2,
    command: 3,
    trip_start: 4,
    trip_end: 5
  }

  validates :scooter, :event_type, :data, presence: true
  store_accessor :data
end
