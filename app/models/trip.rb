class Trip < ApplicationRecord
  belongs_to :user
  belongs_to :scooter
  belongs_to :start_telemetry, class_name: "Telemetry", optional: true
  belongs_to :end_telemetry, class_name: "Telemetry", optional: true

  validates :started_at, presence: true
  validates :start_lat, presence: true
  validates :start_lng, presence: true

  validate :no_other_trips_in_progress, on: :create

  scope :completed, -> { where.not(ended_at: nil) }
  scope :in_progress, -> { where(ended_at: nil) }
  scope :with_telemetry, -> { where.not(start_telemetry_id: nil, end_telemetry_id: nil) }
  scope :with_low_end_battery, -> { joins(:end_telemetry).where("telemetries.battery0_level + telemetries.battery1_level < 20") }
  scope :with_sufficient_start_battery, -> { joins(:start_telemetry).where("telemetries.battery0_level + telemetries.battery1_level >= 25") }

  before_create :complete_in_progress_trips
  before_create :associate_start_telemetry
  before_update :associate_end_telemetry, if: -> { ended_at_changed? && ended_at.present? }

  def duration
    return nil unless ended_at
    ended_at - started_at
  end

  def distance_km
    return nil unless distance
    distance / 1000.0
  end

  def next_trip
    user.trips
        .where("started_at > ?", started_at)
        .order(started_at: :asc)
        .first
  end

  def previous_trip
    user.trips
        .where("started_at < ?", started_at)
        .order(started_at: :desc)
        .first
  end

  private

  def no_other_trips_in_progress
    if scooter.trips.in_progress.exists?
      errors.add(:base, "Cannot start a new trip while another trip is in progress")
    end
  end

  def complete_in_progress_trips
    scooter.trips.in_progress.each do |trip|
      trip.update!(
        ended_at: Time.current,
        end_lat: scooter.lat,
        end_lng: scooter.lng,
        distance: calculate_distance(trip),
        avg_speed: calculate_average_speed(trip)
      )
    end
  end

  def calculate_distance(trip)
    return nil unless trip.start_lat && trip.start_lng && scooter.lat && scooter.lng

    distance_km = calculate_distance_between(
      trip.start_lat, trip.start_lng,
      scooter.lat, scooter.lng
    )

    return nil unless distance_km
    (distance_km * 1000).round # Convert to meters
  end

  def calculate_average_speed(trip)
    return nil unless trip.started_at && trip.distance

    duration_hours = (Time.current - trip.started_at) / 1.hour
    return nil if duration_hours.zero?

    # Convert distance from meters to kilometers and divide by duration in hours
    (trip.distance / 1000.0 / duration_hours).round(1)
  end

  def calculate_distance_between(lat1, lng1, lat2, lng2)
    return nil unless lat1 && lng1 && lat2 && lng2

    rad_per_deg = Math::PI/180  # PI / 180
    rkm = 6371                  # Earth radius in kilometers

    dlat_rad = (lat2-lat1) * rad_per_deg
    dlng_rad = (lng2-lng1) * rad_per_deg

    lat1_rad = lat1 * rad_per_deg
    lat2_rad = lat2 * rad_per_deg

    a = Math.sin(dlat_rad/2)**2 + Math.cos(lat1_rad) * Math.cos(lat2_rad) * Math.sin(dlng_rad/2)**2
    c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))
    rkm * c # Distance in kilometers
  end

  def associate_start_telemetry
    # Find the most recent telemetry for the scooter at the time of trip start
    latest_telemetry = scooter.telemetries
                              .where("created_at <= ?", started_at)
                              .order(created_at: :desc)
                              .first

    self.start_telemetry = latest_telemetry if latest_telemetry
  end

  def associate_end_telemetry
    # Find the most recent telemetry for the scooter at the time of trip end
    latest_telemetry = scooter.telemetries
                              .where("created_at <= ?", ended_at)
                              .order(created_at: :desc)
                              .first

    self.end_telemetry = latest_telemetry if latest_telemetry
  end
end
