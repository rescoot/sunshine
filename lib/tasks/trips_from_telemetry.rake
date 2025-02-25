namespace :trips do
  desc "Generate trips from historical telemetry data"
  task generate_from_telemetry: :environment do
    # Use constants from TripDetectionService
    MIN_DURATION_MINUTES = TripDetectionService::MIN_DURATION_MINUTES
    MIN_DISTANCE_KM = TripDetectionService::MIN_DISTANCE_KM

    puts "Starting trip generation from historical telemetry data"
    puts "Minimum trip requirements: #{MIN_DURATION_MINUTES} minutes, #{MIN_DISTANCE_KM}km"

    # Track statistics
    stats = {
      scooters_processed: 0,
      potential_trips_found: 0,
      valid_trips_created: 0,
      invalid_trips_skipped: 0,
      telemetries_processed: 0,
      driving_telemetries: 0,
      non_driving_telemetries: 0
    }

    # Process each scooter
    Scooter.find_each do |scooter|
      puts "Processing scooter: #{scooter.name} (#{scooter.vin})"
      stats[:scooters_processed] += 1

      # Get all telemetry for this scooter, ordered chronologically
      telemetries = scooter.telemetries.order(created_at: :asc)

      if telemetries.empty?
        puts "  No telemetry data found for this scooter"
        next
      end

      puts "  Found #{telemetries.count} telemetry records"

      # Debug: Check state distribution
      driving_count = telemetries.where(state: "driving").count
      ready_to_drive_count = telemetries.where(state: "ready-to-drive").count
      parked_count = telemetries.where(state: "parked").count
      standby_count = telemetries.where(state: "stand-by").count
      puts "  State distribution: driving=#{driving_count}, ready-to-drive=#{ready_to_drive_count}, parked=#{parked_count}, stand-by=#{standby_count}, other=#{telemetries.count - driving_count - ready_to_drive_count - parked_count - standby_count}"

      stats[:driving_telemetries] += (driving_count + ready_to_drive_count + parked_count)
      stats[:non_driving_telemetries] += (standby_count + telemetries.count - driving_count - ready_to_drive_count - parked_count - standby_count)

      # Variables to track state
      current_trip_start = nil
      previous_telemetry = nil

      # Process telemetries in chronological order
      telemetries.each_with_index do |telemetry, index|
        stats[:telemetries_processed] += 1

        # Debug: Print telemetry state periodically
        if index % 1000 == 0
          puts "  Processing telemetry ##{telemetry.id} (#{telemetry.created_at}): state=#{telemetry.state}"
        end

        # Check for state transitions
        if previous_telemetry
          # Check if this telemetry would start a trip
          if TripDetectionService.would_start_trip?(telemetry, previous_telemetry) && current_trip_start.nil?
            current_trip_start = telemetry
            puts "  Starting new trip at #{telemetry.created_at} (state transition to #{telemetry.state})"
          end

          # Check if this telemetry would end a trip
          if TripDetectionService.would_end_trip?(telemetry, previous_telemetry) && current_trip_start
            puts "  Ending trip at #{telemetry.created_at} (state transition to #{telemetry.state})"

            # Create a trip
            create_trip(scooter, current_trip_start, telemetry, stats)

            # Reset trip tracking
            current_trip_start = nil
          end
        elsif TripDetectionService.driving_state?(telemetry.state)
          # First telemetry is in a driving state, start a trip
          current_trip_start = telemetry
          puts "  Starting new trip at #{telemetry.created_at} (first telemetry in driving state)"
        end

        # Update previous telemetry
        previous_telemetry = telemetry

        # Handle the last telemetry in the set
        if index == telemetries.size - 1 && current_trip_start
          puts "  Reached end of telemetry data with an active trip"
          puts "  Ending trip at last telemetry: #{telemetry.created_at}"
          create_trip(scooter, current_trip_start, telemetry, stats)
        end
      end
    end

    # Print summary
    puts "\nTrip generation summary:"
    puts "  Scooters processed: #{stats[:scooters_processed]}"
    puts "  Telemetries processed: #{stats[:telemetries_processed]}"
    puts "  Driving telemetries: #{stats[:driving_telemetries]}"
    puts "  Non-driving telemetries: #{stats[:non_driving_telemetries]}"
    puts "  Potential trips found: #{stats[:potential_trips_found]}"
    puts "  Valid trips created: #{stats[:valid_trips_created]}"
    puts "  Invalid trips skipped: #{stats[:invalid_trips_skipped]}"
  end

  def create_trip(scooter, start_telemetry, end_telemetry, stats)
    # Make sure we have valid telemetries
    unless start_telemetry && end_telemetry && start_telemetry.created_at < end_telemetry.created_at
      puts "  WARNING: Invalid trip telemetries, skipping"
      return
    end

    # Get all telemetries for this trip in chronological order
    trip_telemetries = scooter.telemetries
                             .where("created_at BETWEEN ? AND ?",
                                    start_telemetry.created_at,
                                    end_telemetry.created_at)
                             .order(created_at: :asc)

    puts "  Trip duration: #{((end_telemetry.created_at - start_telemetry.created_at) / 60).round} minutes"
    puts "  Trip telemetry points: #{trip_telemetries.count}"

    # Sanity check - if the trip is too long, it's probably not a real trip
    if (end_telemetry.created_at - start_telemetry.created_at) > 24.hours
      puts "  WARNING: Trip duration exceeds 24 hours, likely not a valid trip. Skipping."
      return
    end

    # Calculate distance from odometer values
    total_distance = TripDetectionService.calculate_distance_from_odometer(
      start_telemetry, end_telemetry
    )

    # Ensure distance is an integer
    total_distance = total_distance.to_i

    duration_minutes = (end_telemetry.created_at - start_telemetry.created_at) / 60
    avg_speed = total_distance > 0 ?
                (total_distance / 1000.0) / (duration_minutes / 60.0) :
                0

    # Sanity check for unrealistic speeds
    if avg_speed > 100
      puts "  WARNING: Average speed of #{avg_speed.round(1)}km/h is unrealistic. Skipping."
      return
    end

    stats[:potential_trips_found] += 1

    # Check if trip meets minimum requirements
    if duration_minutes >= MIN_DURATION_MINUTES &&
       total_distance / 1000.0 >= MIN_DISTANCE_KM

      # Find valid GPS coordinates for start and end if needed
      start_lat = start_telemetry.lat
      start_lng = start_telemetry.lng
      end_lat = end_telemetry.lat
      end_lng = end_telemetry.lng

      # If start coordinates are invalid, try to find the first valid GPS location
      if !TripDetectionService.valid_coordinates?(start_lat, start_lng)
        first_valid_gps = TripDetectionService.find_first_valid_gps_location(trip_telemetries)
        if first_valid_gps
          start_lat = first_valid_gps.lat
          start_lng = first_valid_gps.lng

          # Calculate distance from trip start to first valid GPS location
          start_gps_distance = TripDetectionService.calculate_distance_from_odometer(
            start_telemetry, first_valid_gps
          )
        end
      end

      # If end coordinates are invalid, try to find the last valid GPS location
      if !TripDetectionService.valid_coordinates?(end_lat, end_lng)
        last_valid_gps = TripDetectionService.find_last_valid_gps_location(trip_telemetries)
        if last_valid_gps
          end_lat = last_valid_gps.lat
          end_lng = last_valid_gps.lng

          # Calculate distance from last valid GPS location to trip end
          end_gps_distance = TripDetectionService.calculate_distance_from_odometer(
            last_valid_gps, end_telemetry
          )
        end
      end

      # Create the trip
      trip = scooter.trips.create!(
        user: scooter.owner,
        started_at: start_telemetry.created_at,
        start_lat: start_lat,
        start_lng: start_lng,
        start_odometer: start_telemetry.odometer,
        start_telemetry: start_telemetry,
        ended_at: end_telemetry.created_at,
        end_lat: end_lat,
        end_lng: end_lng,
        end_odometer: end_telemetry.odometer,
        end_telemetry: end_telemetry,
        distance: total_distance,
        avg_speed: avg_speed.round(1),
        start_gps_distance: start_gps_distance || 0,
        end_gps_distance: end_gps_distance || 0
      )

      stats[:valid_trips_created] += 1
      puts "  Created trip ##{trip.id}: #{duration_minutes.round} minutes, #{(total_distance/1000.0).round(1)}km, #{avg_speed.round(1)}km/h"

      # Generate trip segments
      puts "  Generating trip segments..."
      trip.send(:generate_trip_segments)
      puts "  Created #{trip.trip_segments.count} segments"
    else
      stats[:invalid_trips_skipped] += 1
      puts "  Trip did not meet minimum requirements (#{duration_minutes.round}min, #{(total_distance/1000.0).round(1)}km, #{avg_speed.round(1)}km/h)"
    end
  end
end
