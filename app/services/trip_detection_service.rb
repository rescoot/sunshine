class TripDetectionService
  # Constants
  MIN_DURATION_MINUTES = 1
  MIN_DISTANCE_KM = 1
  STANDBY_THRESHOLD_MINUTES = 15
  INACTIVITY_TIMEOUT_HOURS = 1

  def self.driving_state?(state)
    state == "ready-to-drive" || state == "parked"
  end

  def self.non_driving_state?(state)
    !driving_state?(state)
  end

  def self.valid_coordinates?(lat, lng)
    lat && lng && !(lat == 0.0 && lng == 0.0)
  end

  def self.calculate_distance_from_odometer(start_telemetry, end_telemetry)
    if start_telemetry&.odometer && end_telemetry&.odometer &&
       end_telemetry.odometer >= start_telemetry.odometer
      return end_telemetry.odometer - start_telemetry.odometer
    end

    # Fallback to a default value if we can't calculate distance
    0
  end

  def self.trip_meets_requirements?(trip)
    duration_minutes = (trip.ended_at - trip.started_at) / 60
    distance_km = trip.distance.to_f / 1000

    # Sanity check - if the trip is too long, it's probably not a real trip
    if duration_minutes > 24 * 60
      Rails.logger.warn "Trip ##{trip.id} duration exceeds 24 hours, likely not a valid trip"
      return false
    end

    # Sanity check for unrealistic speeds
    avg_speed = distance_km / (duration_minutes / 60.0)
    if avg_speed > 60
      Rails.logger.warn "Trip ##{trip.id} average speed of #{avg_speed.round(1)}km/h is unrealistic"
      return false
    end

    duration_minutes >= MIN_DURATION_MINUTES &&
    distance_km >= MIN_DISTANCE_KM
  end

  def self.calculate_average_speed(trip, distance)
    duration_hours = (trip.ended_at - trip.started_at) / 1.hour
    return nil if duration_hours.zero?

    # Convert distance from meters to kilometers and divide by duration in hours
    (distance / 1000.0 / duration_hours).round(1)
  end

  def self.would_start_trip?(telemetry, previous_telemetry = nil)
    # A telemetry would start a trip if:
    # 1. It's in a driving state (ready-to-drive or parked)
    # 2. The previous telemetry was in a non-driving state or doesn't exist

    return false unless driving_state?(telemetry.state)

    # If we don't have a previous telemetry, this is the first telemetry
    # and it would start a trip if it's in a driving state
    return true unless previous_telemetry

    # If the previous telemetry was in a non-driving state and this one is in a driving state,
    # this would start a trip (state transition)
    non_driving_state?(previous_telemetry.state)
  end

  def self.would_end_trip?(telemetry, previous_telemetry = nil)
    # A telemetry would end a trip if:
    # 1. It's in a non-driving state
    # 2. The previous telemetry was in a driving state

    return false unless non_driving_state?(telemetry.state)

    # If we don't have a previous telemetry, this can't end a trip
    return false unless previous_telemetry

    # If the previous telemetry was in a driving state and this one is in a non-driving state,
    # this would end a trip (state transition)
    driving_state?(previous_telemetry.state)
  end

  # Helper method to find the first valid GPS location in a set of telemetries
  def self.find_first_valid_gps_location(telemetries)
    telemetries.find do |telemetry|
      valid_coordinates?(telemetry.lat, telemetry.lng)
    end
  end

  # Helper method to find the last valid GPS location in a set of telemetries
  def self.find_last_valid_gps_location(telemetries)
    telemetries.reverse_each.find do |telemetry|
      valid_coordinates?(telemetry.lat, telemetry.lng)
    end
  end
end
