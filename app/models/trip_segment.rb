class TripSegment < ApplicationRecord
  belongs_to :trip
  belongs_to :start_telemetry, class_name: "Telemetry"
  belongs_to :end_telemetry, class_name: "Telemetry"

  # Validations
  validates :segment_order, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :distance, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :segment_type, presence: true

  # Scopes
  scope :ordered, -> { order(segment_order: :asc) }

  # Constants
  SEGMENT_TYPES = [ "straight", "turn", "sharp_turn", "u_turn", "loop", "unknown" ].freeze

  # Check if the segment has valid GPS coordinates
  def has_gps_coordinates?
    start_lat.present? && start_lng.present? && end_lat.present? && end_lng.present?
  end

  # Calculate the straight-line distance between start and end points (in meters)
  # This is just for visualization purposes, not for actual distance tracking
  def straight_line_distance
    return nil unless has_gps_coordinates?

    # Simple approximation for visualization purposes
    lat_diff = (end_lat - start_lat) * 111_000 # 1 degree latitude ≈ 111 km
    lng_diff = (end_lng - start_lng) * Math.cos(start_lat * Math::PI / 180) * 111_000
    Math.sqrt(lat_diff**2 + lng_diff**2)
  end
end
