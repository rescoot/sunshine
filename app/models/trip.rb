class Trip < ApplicationRecord
  belongs_to :user
  belongs_to :scooter

  validates :started_at, presence: true
  validates :start_lat, presence: true
  validates :start_lng, presence: true

  scope :completed, -> { where.not(ended_at: nil) }
  scope :in_progress, -> { where(ended_at: nil) }

  def duration
    return nil unless ended_at
    ended_at - started_at
  end

  def distance_km
    return nil unless distance
    distance / 1000.0
  end
end
