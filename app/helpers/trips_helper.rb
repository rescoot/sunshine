# app/helpers/trips_helper.rb
module TripsHelper
  def trip_status_badge(trip)
    if trip.ended_at.nil?
      content_tag(:span, 'In Progress', class: 'status-badge in-progress')
    else
      content_tag(:span, 'Completed', class: 'status-badge completed')
    end
  end

  def format_trip_distance(trip)
    return 'N/A' unless trip.distance

    distance_km = trip.distance / 1000.0
    if distance_km < 1
      "#{(distance_km * 1000).round} m"
    else
      "#{distance_km.round(2)} km"
    end
  end

  def format_trip_duration(trip)
    return 'In Progress' unless trip.ended_at

    duration = trip.ended_at - trip.started_at
    hours = duration / 1.hour
    minutes = (duration % 1.hour) / 1.minute

    if hours >= 1
      "#{hours.floor}h #{minutes.floor}m"
    else
      "#{minutes.floor}m"
    end
  end

  def format_trip_speed(trip)
    return 'N/A' unless trip.avg_speed
    "#{trip.avg_speed.round(1)} km/h"
  end

  def format_coordinates(lat, lng)
    return 'N/A' unless lat && lng
    "#{lat.round(6)}, #{lng.round(6)}"
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
end
