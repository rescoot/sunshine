module TripsHelper
  def trip_status_badge(trip)
    if trip.ended_at.nil?
      tag.span "In Progress",
        class: "inline-flex items-center rounded-md bg-yellow-50 px-2 py-1 text-xs font-medium text-yellow-800 ring-1 ring-inset ring-yellow-600/20"
    else
      tag.span "Completed",
        class: "inline-flex items-center rounded-md bg-green-50 px-2 py-1 text-xs font-medium text-green-700 ring-1 ring-inset ring-green-600/20"
    end
  end

  def format_trip_distance(trip)
    return tag.span("N/A", class: "text-gray-400") unless trip.distance

    distance_km = trip.distance / 1000.0
    if distance_km < 1
      "#{(distance_km * 1000).round} #{t('units.m')}"
    else
      "#{distance_km.round(2)} #{t('units.km')}"
    end
  end

  def format_trip_duration(trip)
    return tag.span("In Progress", class: "text-yellow-600") unless trip.ended_at

    duration = trip.ended_at - trip.started_at
    hours = duration / 1.hour
    minutes = (duration % 1.hour) / 1.minute

    if hours >= 1
      "#{hours.floor}#{t('units.h')} #{minutes.floor}#{t('units.min')}"
    else
      "#{minutes.floor}#{t('units.min')}"
    end
  end

  def format_trip_speed(trip)
    return tag.span("N/A", class: "text-gray-400") unless trip.avg_speed
    "#{trip.avg_speed.round(1)} #{t('units.kmh')}"
  end

  def format_coordinates(lat, lng)
    return tag.span("N/A", class: "text-gray-400") unless lat && lng
    link_to "#{lat.round(6)}, #{lng.round(6)}",
      "https://www.openstreetmap.org/?mlat=#{lat}&mlon=#{lng}&zoom=16",
      target: "_blank",
      class: "text-indigo-600 hover:text-indigo-900 font-mono"
  end

  # Format trip duration in seconds to a human-readable format using translation units
  def format_duration_seconds(duration_seconds)
    return nil unless duration_seconds

    hours = (duration_seconds / 3600).floor
    minutes = ((duration_seconds % 3600) / 60).floor

    if hours > 0
      "#{hours}#{t('units.h')} #{minutes}#{t('units.min')}"
    else
      "#{minutes}#{t('units.min')}"
    end
  end
end
