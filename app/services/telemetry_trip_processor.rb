class TelemetryTripProcessor
  # Use constants from TripDetectionService
  MIN_DURATION_MINUTES = TripDetectionService::MIN_DURATION_MINUTES
  MIN_DISTANCE_KM = TripDetectionService::MIN_DISTANCE_KM
  STANDBY_THRESHOLD_MINUTES = TripDetectionService::STANDBY_THRESHOLD_MINUTES
  INACTIVITY_TIMEOUT_HOURS = TripDetectionService::INACTIVITY_TIMEOUT_HOURS

  def initialize(telemetry)
    @telemetry = telemetry
    @scooter = telemetry.scooter
  end

  def process
    # Process the telemetry for trip management
    # No longer skipping telemetries with invalid location data
    process_trip_state
    check_for_timed_out_trips
  end

  # Public method for the TripFinalizationJob to use
  def end_trip(end_telemetry)
    trip = @scooter.trips.in_progress.first
    return unless trip

    # Calculate distance from odometer values
    total_distance = TripDetectionService.calculate_distance_from_odometer(
      trip.start_telemetry, end_telemetry
    )

    # Ensure distance is an integer
    total_distance = total_distance.to_i

    # First update trip with end data (without avg_speed)
    trip.update!(
      ended_at: end_telemetry.created_at,
      end_lat: end_telemetry.lat,
      end_lng: end_telemetry.lng,
      end_odometer: end_telemetry.odometer,
      end_telemetry: end_telemetry,
      distance: total_distance
    )

    # Now that ended_at is set, calculate and update the average speed
    avg_speed = TripDetectionService.calculate_average_speed(trip, total_distance)
    trip.update!(avg_speed: avg_speed)

    # Validate the trip meets minimum requirements
    unless TripDetectionService.trip_meets_requirements?(trip)
      Rails.logger.info "Trip ##{trip.id} did not meet minimum requirements, deleting"
      trip.destroy
      return
    end

    Rails.logger.info "Ended trip ##{trip.id} for scooter #{@scooter.vin}"

    # Check achievements for the trip's user after trip completion
    trip.user.check_achievements if trip.user
  end

  private

  def process_trip_state
    # Get the previous telemetry to check for state transitions
    previous_telemetry = get_previous_telemetry

    # Check if this telemetry would start a trip
    if TripDetectionService.would_start_trip?(@telemetry, previous_telemetry) && !active_trip_exists?
      start_new_trip
    end

    # Check if this telemetry would end a trip
    if TripDetectionService.would_end_trip?(@telemetry, previous_telemetry) && active_trip_exists?
      end_trip(@telemetry)
    end
  end

  def get_previous_telemetry
    # Get the most recent telemetry before this one
    @scooter.telemetries
           .where("created_at < ?", @telemetry.created_at)
           .order(created_at: :desc)
           .first
  end

  def check_for_timed_out_trips
    # Check for trips that should be ended due to inactivity
    check_inactivity_timeouts
  end

  def start_new_trip
    # Create a new trip record
    trip = @scooter.trips.create!(
      user: determine_trip_user,
      started_at: @telemetry.created_at,
      start_lat: @telemetry.lat,
      start_lng: @telemetry.lng,
      start_odometer: @telemetry.odometer,
      start_telemetry: @telemetry
    )

    Rails.logger.info "Started new trip ##{trip.id} for scooter #{@scooter.vin}"
  end

  def check_inactivity_timeouts
    # End any trips that haven't had telemetry updates in 1+ hour
    @scooter.trips.in_progress.each do |trip|
      last_telemetry = @scooter.telemetries
                              .where("created_at > ?", trip.started_at)
                              .order(created_at: :desc)
                              .first

      if last_telemetry && last_telemetry.created_at <= INACTIVITY_TIMEOUT_HOURS.hours.ago
        end_trip(last_telemetry)
      end
    end
  end

  def active_trip_exists?
    @scooter.trips.in_progress.exists?
  end

  def determine_trip_user
    # Use the scooter's method to determine the trip user
    # Pass the telemetry timestamp to find the most recent unlock command
    @scooter.determine_trip_user(@telemetry.created_at)
  end
end
