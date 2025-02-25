class Trip < ApplicationRecord
  belongs_to :user
  belongs_to :scooter
  belongs_to :start_telemetry, class_name: "Telemetry", optional: true
  belongs_to :end_telemetry, class_name: "Telemetry", optional: true
  has_many :trip_segments, -> { ordered }, dependent: :destroy

  validates :started_at, presence: true

  validate :no_other_trips_in_progress, on: :create

  scope :completed, -> { where.not(ended_at: nil) }
  scope :in_progress, -> { where(ended_at: nil) }
  scope :with_telemetry, -> { where.not(start_telemetry_id: nil, end_telemetry_id: nil) }
  scope :with_low_end_battery, -> { joins(:end_telemetry).where("telemetries.battery0_level + telemetries.battery1_level < 20") }
  scope :with_sufficient_start_battery, -> { joins(:start_telemetry).where("telemetries.battery0_level + telemetries.battery1_level >= 25") }
  scope :with_gps_data, -> { where.not(start_lat: nil, start_lng: nil, end_lat: nil, end_lng: nil) }
  scope :without_gps_data, -> { where("start_lat IS NULL OR start_lng IS NULL OR end_lat IS NULL OR end_lng IS NULL") }

  before_create :complete_in_progress_trips
  before_create :associate_start_telemetry
  before_update :associate_end_telemetry, if: -> { ended_at_changed? && ended_at.present? }
  after_create :generate_trip_segments
  after_update :generate_trip_segments, if: -> { saved_change_to_ended_at? && ended_at.present? }

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

  # Check if the trip has valid GPS coordinates
  def has_gps_coordinates?
    start_lat.present? && start_lng.present? && end_lat.present? && end_lng.present?
  end

  # Get the first valid GPS location from telemetries
  def find_first_valid_gps_location
    return nil unless start_telemetry && end_telemetry

    # Get all telemetries for this trip in chronological order
    trip_telemetries = scooter.telemetries
                             .where("created_at BETWEEN ? AND ?", started_at, ended_at)
                             .order(created_at: :asc)

    # Find the first telemetry with valid GPS coordinates
    first_valid = trip_telemetries.find do |telemetry|
      telemetry.lat.present? && telemetry.lng.present? &&
      !(telemetry.lat == 0.0 && telemetry.lng == 0.0)
    end

    first_valid
  end

  # Get the last valid GPS location from telemetries
  def find_last_valid_gps_location
    return nil unless start_telemetry && end_telemetry

    # Get all telemetries for this trip in reverse chronological order
    trip_telemetries = scooter.telemetries
                             .where("created_at BETWEEN ? AND ?", started_at, ended_at)
                             .order(created_at: :desc)

    # Find the first (last chronologically) telemetry with valid GPS coordinates
    last_valid = trip_telemetries.find do |telemetry|
      telemetry.lat.present? && telemetry.lng.present? &&
      !(telemetry.lat == 0.0 && telemetry.lng == 0.0)
    end

    last_valid
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
    # Use odometer values if available
    if trip.start_telemetry&.odometer && scooter.odometer && scooter.odometer >= trip.start_telemetry.odometer
      return scooter.odometer - trip.start_telemetry.odometer
    end

    # Fallback to a default value if we can't calculate distance
    0
  end

  def calculate_average_speed(trip)
    return nil unless trip.started_at && trip.distance

    duration_hours = (Time.current - trip.started_at) / 1.hour
    return nil if duration_hours.zero?

    # Convert distance from meters to kilometers and divide by duration in hours
    (trip.distance / 1000.0 / duration_hours).round(1)
  end

  def associate_start_telemetry
    # Find the most recent telemetry for the scooter at the time of trip start
    latest_telemetry = scooter.telemetries
                              .where("created_at <= ?", started_at)
                              .order(created_at: :desc)
                              .first

    self.start_telemetry = latest_telemetry if latest_telemetry

    # Try to find valid GPS coordinates for the trip start
    if latest_telemetry && (self.start_lat.nil? || self.start_lng.nil? ||
                           (self.start_lat == 0.0 && self.start_lng == 0.0))
      first_valid_gps = find_first_valid_gps_location
      if first_valid_gps
        self.start_lat = first_valid_gps.lat
        self.start_lng = first_valid_gps.lng

        # Calculate distance from trip start to first valid GPS location
        if latest_telemetry.odometer && first_valid_gps.odometer &&
           first_valid_gps.odometer >= latest_telemetry.odometer
          self.start_gps_distance = first_valid_gps.odometer - latest_telemetry.odometer
        end
      end
    end
  end

  def associate_end_telemetry
    # Find the most recent telemetry for the scooter at the time of trip end
    latest_telemetry = scooter.telemetries
                              .where("created_at <= ?", ended_at)
                              .order(created_at: :desc)
                              .first

    self.end_telemetry = latest_telemetry if latest_telemetry

    # Try to find valid GPS coordinates for the trip end
    if latest_telemetry && (self.end_lat.nil? || self.end_lng.nil? ||
                           (self.end_lat == 0.0 && self.end_lng == 0.0))
      last_valid_gps = find_last_valid_gps_location
      if last_valid_gps
        self.end_lat = last_valid_gps.lat
        self.end_lng = last_valid_gps.lng

        # Calculate distance from last valid GPS location to trip end
        if last_valid_gps.odometer && latest_telemetry.odometer &&
           latest_telemetry.odometer >= last_valid_gps.odometer
          self.end_gps_distance = latest_telemetry.odometer - last_valid_gps.odometer
        end
      end
    end
  end

  def generate_trip_segments
    # Only generate segments for completed trips with telemetry
    return unless ended_at && start_telemetry && end_telemetry

    # Clear existing segments
    trip_segments.destroy_all

    # Get all telemetries for this trip in chronological order
    trip_telemetries = scooter.telemetries
                             .where("created_at BETWEEN ? AND ?", started_at, ended_at)
                             .order(created_at: :asc)
                             .to_a

    # Need at least 2 telemetries to create segments
    return if trip_telemetries.size < 2

    # Filter out telemetries with invalid GPS coordinates and outliers
    valid_telemetries = filter_valid_telemetries(trip_telemetries)

    # Need at least 2 valid telemetries to create segments
    return if valid_telemetries.size < 2

    # Group telemetries into meaningful segments
    segments = create_meaningful_segments(valid_telemetries)

    # Create the segments in the database
    create_segments_from_groups(segments)

    # If no segments were created, create at least one segment for the entire trip
    if trip_segments.count == 0 && valid_telemetries.size >= 2
      create_segment_from_telemetries(valid_telemetries.first, valid_telemetries.last, 0)
    end

    # Ensure segments are connected
    connect_segments if trip_segments.count > 1
  end

  # Filter out invalid telemetries and outliers
  def filter_valid_telemetries(telemetries)
    valid_telemetries = []
    previous_valid = nil

    telemetries.each do |telemetry|
      if telemetry.lat.present? && telemetry.lng.present? &&
         !(telemetry.lat == 0.0 && telemetry.lng == 0.0) &&
         (previous_valid.nil? || !is_gps_outlier?(previous_valid, telemetry))
        valid_telemetries << telemetry
        previous_valid = telemetry
      end
    end

    valid_telemetries
  end

  # Group telemetries into meaningful segments based on simple rules
  def create_meaningful_segments(telemetries)
    # Constants for segment creation - configurable via environment variables
    max_segment_length = ENV.fetch("TRIP_MAX_SEGMENT_LENGTH", 500).to_i # meters
    max_bearing_change = ENV.fetch("TRIP_MAX_SEGMENT_BEARING_CHANGE", 5).to_i # degrees
    max_speed_change = ENV.fetch("TRIP_MAX_SEGMENT_SPEED_CHANGE", 5).to_i # km/h

    segments = []
    current_segment = []

    # Add the first telemetry to the current segment
    current_segment << telemetries.first
    segment_start_telemetry = telemetries.first
    last_bearing = nil
    last_speed = telemetries.first.speed

    # Process the remaining telemetries
    telemetries[1..-1].each do |telemetry|
      previous_telemetry = current_segment.last

      # Skip if coordinates are too close or identical
      if (previous_telemetry.lat - telemetry.lat).abs < 1e-7 &&
         (previous_telemetry.lng - telemetry.lng).abs < 1e-7
        current_segment << telemetry
        next
      end

      # Calculate bearing between previous and current telemetry
      current_bearing = calculate_bearing(
        previous_telemetry.lat, previous_telemetry.lng,
        telemetry.lat, telemetry.lng
      )

      # Set initial bearing if this is the first valid bearing
      last_bearing = current_bearing if last_bearing.nil?

      # Calculate bearing difference
      bearing_diff = bearing_difference(last_bearing, current_bearing)

      # Calculate distance from segment start
      distance_from_start = calculate_segment_distance(segment_start_telemetry, telemetry)

      # Calculate speed difference
      speed_diff = (telemetry.speed - last_speed).abs

      # Check if we need to start a new segment
      start_new_segment = false

      # Check distance threshold
      if distance_from_start > max_segment_length
        start_new_segment = true
      end

      # Check bearing threshold (only if bearing change is significant)
      if bearing_diff > max_bearing_change
        start_new_segment = true
      end

      # Check speed threshold
      if speed_diff > max_speed_change
        start_new_segment = true
      end

      if start_new_segment && current_segment.size >= 2
        # Finalize the current segment
        segments << current_segment

        # Start a new segment with the previous telemetry
        # This creates a clean break point and allows for precise turn segments
        current_segment = [ previous_telemetry, telemetry ]
        segment_start_telemetry = previous_telemetry
      else
        # Add the current telemetry to the segment
        current_segment << telemetry
      end

      # Update last bearing and speed
      last_bearing = current_bearing
      last_speed = telemetry.speed
    end

    # Add the last segment if it has at least 2 telemetries
    segments << current_segment if current_segment.size >= 2

    # Ensure we have the final segment to the trip end point
    # This is important to make sure we don't miss the last part of the trip
    if segments.any? && end_telemetry
      last_segment = segments.last

      # If the last telemetry in our segments is not the end telemetry of the trip,
      # add a segment from the last segment's end to the trip's end telemetry
      if last_segment.last != end_telemetry
        # Only add if the coordinates are different
        if !coordinates_match?(last_segment.last, end_telemetry)
          segments << [ last_segment.last, end_telemetry ]
        end
      end
    end

    # Process segments to identify turns
    process_segments_for_turns(segments)
  end

  # Process segments to identify turns and create short turn segments
  def process_segments_for_turns(segments)
    processed_segments = []

    # Keep track of the last bearing to detect sequential turns
    last_bearing = nil
    last_turn_index = -1 # Track the index of the last turn segment

    segments.each_with_index do |segment, index|
      # Skip segments that are too short
      next if segment.size < 2

      # Calculate the overall bearing of this segment
      start_t = segment.first
      end_t = segment.last
      segment_bearing = calculate_bearing(start_t.lat, start_t.lng, end_t.lat, end_t.lng)

      # Set initial bearing if this is the first valid segment
      if last_bearing.nil?
        last_bearing = segment_bearing
        processed_segments << segment
        next
      end

      # Calculate bearing difference from the last segment
      bearing_diff = bearing_difference(last_bearing, segment_bearing)

      # If there's a significant bearing change, create a turn segment
      if bearing_diff > DIRECTION_CHANGE_THRESHOLD
        # Check if this is a sequential turn (close to the last turn)
        is_sequential_turn = (index - last_turn_index <= 2) && (last_turn_index >= 0)

        # Create a very short turn segment using just the connecting points
        # This ensures the turn segment is as small as possible
        prev_segment = processed_segments.last
        prev_end_t = prev_segment.last

        # Determine the turn type based on the bearing difference
        # Only classify as u-turn if the bearing difference is very large (> 150 degrees)
        # and not too large (< 300 degrees) to avoid classifying small bearing changes as u-turns
        turn_type = if bearing_diff > U_TURN_THRESHOLD && bearing_diff < 300
                      # For sequential turns, be more conservative about u-turns
                      is_sequential_turn ? "sharp_turn" : "u_turn"
        elsif bearing_diff > SHARP_TURN_THRESHOLD && bearing_diff < 300
                      "sharp_turn"
        else
                      "turn"
        end

        # Create the turn segment
        turn_segment = [ prev_end_t, segment.first ]

        # Add the turn segment with the appropriate type
        turn_segment.instance_variable_set(:@segment_type, turn_type)
        processed_segments << turn_segment

        # Update the last turn index if this is a significant turn
        if !is_sequential_turn || bearing_diff > SHARP_TURN_THRESHOLD
          last_turn_index = processed_segments.size - 1
        end
      end

      # Add the current segment
      processed_segments << segment

      # Update the last bearing
      last_bearing = segment_bearing
    end

    processed_segments
  end

  # Create database records for the segments
  def create_segments_from_groups(segments)
    # Ensure we have at least one segment
    return if segments.empty?

    # Create a continuous path of segments
    segments.each_with_index do |segment, index|
      # For the final segment, we allow it to have just 1 telemetry if it's the end telemetry
      if segment.size < 2
        # If this is the last segment and it contains the end telemetry, create it anyway
        if index == segments.size - 1 && segment.last == end_telemetry
          # Create a segment from the last segment's end to the trip's end telemetry
          create_segment_from_telemetries(segment.first, segment.last, index, "straight")
        else
          next
        end
      else
        # Check if this segment has a pre-determined type (set by process_segments_for_turns)
        segment_type = segment.instance_variable_defined?(:@segment_type) ?
                      segment.instance_variable_get(:@segment_type) : nil

        # Create a segment from the first to the last telemetry in the group
        create_segment_from_telemetries(segment.first, segment.last, index, segment_type)
      end
    end

    # Double-check that we have a segment to the end telemetry
    if end_telemetry && trip_segments.any?
      last_segment = trip_segments.ordered.last

      # If the last segment doesn't end at the trip's end telemetry, add a final segment
      if last_segment.end_telemetry_id != end_telemetry.id
        # Create a final segment from the last segment's end to the trip's end telemetry
        create_segment_from_telemetries(last_segment.end_telemetry, end_telemetry, trip_segments.count, "straight")
      end
    end
  end

  # Connect segments that have gaps between them
  def connect_segments
    ordered_segments = trip_segments.ordered.to_a

    # Iterate through segments and connect any that don't touch
    (0...(ordered_segments.size - 1)).each do |i|
      current_segment = ordered_segments[i]
      next_segment = ordered_segments[i + 1]

      # Check if the end of the current segment matches the start of the next segment
      if current_segment.end_lat != next_segment.start_lat ||
          current_segment.end_lng != next_segment.start_lng

        # Create a connecting segment
        # Use an integer for segment_order (validation requires integer)
        connector_order = current_segment.segment_order + 1

        # Shift all subsequent segments to make room for the connector
        trip_segments.where("segment_order > ?", current_segment.segment_order)
                    .order(segment_order: :desc)
                    .each do |segment|
          segment.update_column(:segment_order, segment.segment_order + 1)
        end

        trip_segments.create!(
          start_telemetry: current_segment.end_telemetry,
          end_telemetry: next_segment.start_telemetry,
          start_lat: current_segment.end_lat,
          start_lng: current_segment.end_lng,
          end_lat: next_segment.start_lat,
          end_lng: next_segment.start_lng,
          distance: 1, # Minimal distance for connecting segments
          segment_order: connector_order, # Integer value
          segment_type: "straight", # Use straight type instead of connector
          speed: 0 # Connecting segments don't have a meaningful speed
        )
      end
    end

    # Reorder segments to ensure they're in the correct order
    reorder_segments
  end

  # Reorder segments to ensure they're in the correct order
  def reorder_segments
    # Get all segments ordered by their current segment_order
    segments = trip_segments.order(:segment_order).to_a

    # Reassign segment_order values as consecutive integers
    segments.each_with_index do |segment, index|
      segment.update_column(:segment_order, index)
    end
  end

  # Create a segment from two telemetries
  def create_segment_from_telemetries(start_telemetry, end_telemetry, segment_order, override_segment_type = nil)
    # Calculate segment distance from odometer
    segment_distance = calculate_segment_distance(start_telemetry, end_telemetry)

    # Skip segments with zero distance (unless it's the only segment)
    return false if segment_distance == 0 && trip_segments.count > 0

    # Use the telemetry's speed value instead of calculating our own
    # Average the start and end telemetry speeds
    segment_speed = (start_telemetry.speed + end_telemetry.speed) / 2.0

    # Cap unrealistic speeds
    segment_speed = [ segment_speed, 65 ].min

    # Use the provided segment type if available, otherwise determine it
    segment_type = override_segment_type || determine_segment_type(start_telemetry, end_telemetry)

    # Create the segment
    trip_segments.create!(
      start_telemetry: start_telemetry,
      end_telemetry: end_telemetry,
      start_lat: start_telemetry.lat,
      start_lng: start_telemetry.lng,
      end_lat: end_telemetry.lat,
      end_lng: end_telemetry.lng,
      distance: segment_distance,
      segment_order: segment_order,
      segment_type: segment_type,
      speed: segment_speed.round(1)
    )

    true
  end

  # Calculate segment distance from odometer
  def calculate_segment_distance(start_telemetry, end_telemetry)
    # Only use odometer values - no fallback to straight-line calculation
    if start_telemetry.odometer && end_telemetry.odometer &&
       end_telemetry.odometer >= start_telemetry.odometer
      return (end_telemetry.odometer - start_telemetry.odometer).to_i
    end

    # If we can't calculate from odometer, return 0
    # These segments will be merged with others in merge_short_segments
    0
  end

  # Calculate segment speed in km/h
  def calculate_segment_speed(distance, duration_seconds)
    if duration_seconds > 0 && distance > 0
      (distance / 1000.0) / (duration_seconds / 3600.0)
    else
      0
    end
  end

  # Constants for segment generation - configurable via environment variables
  DIRECTION_CHANGE_THRESHOLD = ENV.fetch("TRIP_DIRECTION_CHANGE_THRESHOLD", 45).to_i # degrees
  SHARP_TURN_THRESHOLD = ENV.fetch("TRIP_SHARP_TURN_THRESHOLD", 90).to_i # degrees
  U_TURN_THRESHOLD = ENV.fetch("TRIP_U_TURN_THRESHOLD", 150).to_i # degrees
  MAX_GPS_JUMP_DISTANCE = ENV.fetch("TRIP_MAX_GPS_JUMP_DISTANCE", 1).to_i # kilometers
  MIN_SEGMENT_DISTANCE = ENV.fetch("TRIP_MIN_SEGMENT_DISTANCE", 100).to_i # meters
  MIN_LOOP_DISTANCE = ENV.fetch("TRIP_MIN_LOOP_DISTANCE", 500).to_i # meters

  # Calculate bearing (direction) between two points with improved precision
  # This is a class method so it can be called from the view
  def self.calculate_bearing(lat1, lng1, lat2, lng2)
    # Handle identical or very close coordinates
    if (lat1 - lat2).abs < 1e-7 && (lng1 - lng2).abs < 1e-7
      return 0.0 # Return a default bearing for identical points
    end

    # Convert to radians with higher precision
    lat1_rad = lat1 * Math::PI / 180.0
    lat2_rad = lat2 * Math::PI / 180.0
    lng_diff_rad = (lng2 - lng1) * Math::PI / 180.0

    # Calculate bearing using the Haversine formula for better precision
    y = Math.sin(lng_diff_rad) * Math.cos(lat2_rad)
    x = Math.cos(lat1_rad) * Math.sin(lat2_rad) -
        Math.sin(lat1_rad) * Math.cos(lat2_rad) * Math.cos(lng_diff_rad)

    # Convert to degrees and normalize to 0-360
    bearing = (Math.atan2(y, x) * 180.0 / Math::PI + 360.0) % 360.0

    # Round to reduce floating point precision issues
    bearing.round(6)
  end

  # Instance method version that calls the class method
  def calculate_bearing(lat1, lng1, lat2, lng2)
    self.class.calculate_bearing(lat1, lng1, lat2, lng2)
  end

  # Calculate the difference between two bearings with noise filtering
  def bearing_difference(bearing1, bearing2)
    # Calculate the absolute difference between bearings
    diff = (bearing2 - bearing1).abs % 360

    # Use the smaller angle (handle cases where diff > 180)
    diff = 360 - diff if diff > 180

    # Apply noise threshold - ignore very small changes that might be GPS noise
    # Use a smaller threshold to preserve more detail
    noise_threshold = ENV.fetch("TRIP_BEARING_NOISE_THRESHOLD", 2).to_i # degrees
    diff < noise_threshold ? 0 : diff
  end

  # Detect unrealistic jumps in GPS coordinates
  def is_gps_outlier?(telemetry1, telemetry2, max_distance_km = MAX_GPS_JUMP_DISTANCE)
    return true unless telemetry1 && telemetry2
    return true unless telemetry1.lat.present? && telemetry1.lng.present? &&
                       telemetry2.lat.present? && telemetry2.lng.present?

    # Calculate straight-line distance between points
    lat_diff = (telemetry2.lat - telemetry1.lat) * 111 # 1 degree ≈ 111 km
    lng_diff = (telemetry2.lng - telemetry1.lng) * Math.cos(telemetry1.lat * Math::PI / 180) * 111
    distance_km = Math.sqrt(lat_diff**2 + lng_diff**2)

    # If distance exceeds threshold, consider it an outlier
    distance_km > max_distance_km
  end

  # Determine segment type based on bearing change and segment length
  # This method is called by create_segment_from_telemetries which is used in create_segments_from_groups
  # It determines the type of a single segment based on its own characteristics
  def determine_segment_type(start_telemetry, end_telemetry)
    # Check if start and end are at the same location (within a small margin)
    if coordinates_match?(start_telemetry, end_telemetry)
      return "loop"
    end

    # Calculate segment distance
    segment_distance = calculate_segment_distance(start_telemetry, end_telemetry)

    # For very short segments, default to straight
    # These are usually connecting segments or GPS noise
    if segment_distance < 5 # Very short segments (less than 5 meters)
      return "straight"
    end

    # For segments created in process_segments_for_turns, we rely on the bearing difference
    # between adjacent segments to determine if it's a turn. That method creates turn segments
    # at the points where the bearing changes significantly.

    # For segments created directly (like when we only have one segment for the whole trip),
    # we need to analyze the internal bearing changes to determine if it's a turn.

    # Get all telemetries between start and end
    intermediate_telemetries = get_intermediate_telemetries(start_telemetry, end_telemetry)

    # If we have enough telemetries, analyze the internal bearing changes
    if intermediate_telemetries.size >= 3
      # Calculate bearings between consecutive points
      bearings = calculate_bearings(intermediate_telemetries)

      # Find the maximum bearing change
      max_bearing_change = 0
      bearings.each_cons(2) do |b1, b2|
        change = bearing_difference(b1, b2)
        max_bearing_change = change if change > max_bearing_change
      end

      # Classify based on the maximum bearing change
      # Only classify as u-turn if the bearing difference is very large (> 150 degrees)
      # and not too large (< 300 degrees) to avoid classifying small bearing changes as u-turns
      if max_bearing_change > U_TURN_THRESHOLD && max_bearing_change < 300 # > 150 degrees
        return "u_turn"
      elsif max_bearing_change > SHARP_TURN_THRESHOLD && max_bearing_change < 300 # > 90 degrees
        return "sharp_turn"
      elsif max_bearing_change > DIRECTION_CHANGE_THRESHOLD # > 45 degrees
        return "turn"
      end
    end

    # Default to straight if we couldn't determine a turn type
    "straight"
  end

  # Get all telemetries between start and end for a segment
  def get_intermediate_telemetries(start_telemetry, end_telemetry)
    scooter.telemetries
           .where("created_at BETWEEN ? AND ?", start_telemetry.created_at, end_telemetry.created_at)
           .order(created_at: :asc)
           .to_a
  end

  # Check if coordinates match within a small margin
  def coordinates_match?(telemetry1, telemetry2, precision = 4)
    telemetry1.lat.to_f.round(precision) == telemetry2.lat.to_f.round(precision) &&
    telemetry1.lng.to_f.round(precision) == telemetry2.lng.to_f.round(precision)
  end

  # Check if a segment forms a loop
  def is_loop?(start_telemetry, end_telemetry, telemetries)
    # A loop should:
    # 1. Start and end at approximately the same location
    # 2. Have a minimum distance traveled
    # 3. Have a path that deviates from a straight line

    # Check if start and end are close
    return false unless coordinates_match?(start_telemetry, end_telemetry)

    # Calculate total distance traveled in the segment
    total_distance = 0
    telemetries.each_cons(2) do |t1, t2|
      if t1.odometer && t2.odometer && t2.odometer >= t1.odometer
        total_distance += (t2.odometer - t1.odometer)
      end
    end

    # A loop should have a minimum distance
    return false if total_distance < MIN_LOOP_DISTANCE

    # Check if the path deviates from a straight line
    # (A real loop would have significant bearing changes)
    bearings = calculate_bearings(telemetries)
    max_bearing_change = calculate_max_bearing_change(bearings)

    # A loop should have at least one significant direction change
    max_bearing_change > DIRECTION_CHANGE_THRESHOLD
  end

  # Calculate bearings between consecutive points in a list of telemetries
  def calculate_bearings(telemetries)
    bearings = []
    telemetries.each_cons(2) do |t1, t2|
      # Skip invalid coordinates
      next unless t1.lat && t1.lng && t2.lat && t2.lng
      next if t1.lat == 0 && t1.lng == 0
      next if t2.lat == 0 && t2.lng == 0

      bearing = calculate_bearing(t1.lat, t1.lng, t2.lat, t2.lng)
      bearings << bearing
    end
    bearings
  end

  # Calculate the maximum bearing change in a list of bearings
  def calculate_max_bearing_change(bearings)
    return 0 if bearings.size < 2

    max_change = 0
    bearings.each_cons(2) do |b1, b2|
      change = bearing_difference(b1, b2)
      max_change = change if change > max_change
    end

    max_change
  end
end
