module ApplicationHelper
  def format_distance(meters)
    if meters >= 1000
      "#{number_with_precision(meters/1000.0, precision: 2)} #{t('units.km')}"
    else
      "#{number_with_precision(meters, precision: 0)} #{t('units.m')}"
    end
  end

  def format_speed(kmh)
    "#{number_with_precision(kmh, precision: 1)} #{t('units.kmh')}"
  end

  def format_duration(start_time, end_time)
    return nil unless end_time

    duration = end_time - start_time
    hours = (duration / 1.hour).floor
    minutes = ((duration % 1.hour) / 1.minute).floor

    if hours > 0
      "#{hours}#{t('units.h')} #{minutes}#{t('units.m')}"
    else
      "#{minutes}#{t('units.m')}"
    end
  end
end
