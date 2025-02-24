class TripManagementService
  def initialize(scooter)
    @scooter = scooter
  end

  def current_trip
    @scooter.trips&.in_progress&.last
  end

  def start_trip
    return if current_trip

    @scooter.trips.create!(
      user: @scooter.owner,
      started_at: Time.current,
      start_lat: @scooter.lat,
      start_lng: @scooter.lng,
      start_odometer: @scooter.odometer
    )
  end

  def end_trip
    trip = current_trip
    return unless trip

    trip.update!(
      ended_at: Time.current,
      end_lat: @scooter.lat,
      end_lng: @scooter.lng,
      end_odometer: @scooter.odometer,
      distance: @scooter.odometer - trip.start_odometer,
      avg_speed: calculate_average_speed(trip)
    )
  end

  private

  def calculate_average_speed(trip)
    return nil unless trip.started_at && trip.end_odometer && trip.start_odometer

    duration_hours = (Time.current - trip.started_at) / 1.hour
    return nil if duration_hours.zero?

    distance_km = (trip.end_odometer - trip.start_odometer) / 1000.0
    (distance_km / duration_hours).round(1)
  end
end
