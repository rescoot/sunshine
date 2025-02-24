class StatisticsService
  # Time periods for data aggregation
  PERIODS = {
    day: 24.hours,
    week: 1.week,
    month: 1.month,
    year: 1.year
  }.freeze

  # Returns ride statistics data formatted for Chart.js
  def self.ride_statistics(scooter_id, period = :week)
    scooter = Scooter.find(scooter_id)
    time_range = time_range_for_period(period)
    interval = interval_for_period(period)

    # Get trips in the time range
    trips = scooter.trips
                  .where(started_at: time_range)
                  .where.not(ended_at: nil)
                  .order(started_at: :asc)

    # Group data by time intervals
    grouped_data = group_by_time_interval(trips, interval, time_range)

    # Format data for Chart.js
    {
      labels: grouped_data.keys.map { |date| format_date_for_period(date, period) },
      datasets: [
        {
          label: "Distance (km)",
          data: grouped_data.values.map { |data| data[:distance] / 1000.0 },
          borderColor: "#4CAF50",
          backgroundColor: "rgba(76, 175, 80, 0.1)",
          fill: true
        },
        {
          label: "Average Speed (km/h)",
          data: grouped_data.values.map { |data| data[:avg_speed] },
          borderColor: "#2196F3",
          backgroundColor: "rgba(33, 150, 243, 0.1)",
          fill: true
        },
        {
          label: "Trip Count",
          data: grouped_data.values.map { |data| data[:count] },
          borderColor: "#FF9800",
          backgroundColor: "rgba(255, 152, 0, 0.1)",
          fill: true
        }
      ]
    }
  end

  # Returns battery performance data formatted for Chart.js
  def self.battery_performance(scooter_id, period = :week)
    scooter = Scooter.find(scooter_id)
    time_range = time_range_for_period(period)
    interval = interval_for_period(period)

    # Get telemetry data in the time range
    telemetries = scooter.telemetries
                        .where(created_at: time_range)
                        .order(created_at: :asc)

    # Group data by time intervals
    grouped_data = group_telemetry_by_interval(telemetries, interval, time_range)

    # Format data for Chart.js
    {
      labels: grouped_data.keys.map { |date| format_date_for_period(date, period) },
      datasets: [
        {
          label: "Battery 0 Level (%)",
          data: grouped_data.values.map { |data| data[:battery0_level] },
          borderColor: "#4CAF50",
          backgroundColor: "rgba(76, 175, 80, 0.1)",
          fill: true
        },
        {
          label: "Battery 1 Level (%)",
          data: grouped_data.values.map { |data| data[:battery1_level] },
          borderColor: "#2196F3",
          backgroundColor: "rgba(33, 150, 243, 0.1)",
          fill: true
        },
        {
          label: "Estimated Range (km)",
          data: grouped_data.values.map { |data| data[:estimated_range] },
          borderColor: "#FF9800",
          backgroundColor: "rgba(255, 152, 0, 0.1)",
          fill: true
        }
      ]
    }
  end

  # Returns regeneration efficiency data
  def self.regeneration_efficiency(scooter_id, period = :week)
    scooter = Scooter.find(scooter_id)
    time_range = time_range_for_period(period)

    # Get telemetry data with motor current
    telemetries = scooter.telemetries
                        .where(created_at: time_range)
                        .where.not(motor_current: nil)
                        .order(created_at: :asc)

    # Calculate regeneration metrics
    total_regen_time = 0
    total_regen_current = 0
    total_consumption_time = 0
    total_consumption_current = 0

    telemetries.each do |telemetry|
      if telemetry.motor_current < 0 # Regenerating
        total_regen_time += 1
        total_regen_current += telemetry.motor_current.abs
      else # Consuming
        total_consumption_time += 1
        total_consumption_current += telemetry.motor_current
      end
    end

    regen_percentage = total_consumption_time > 0 ?
      (total_regen_current / total_consumption_current * 100).round(2) : 0

    # Format data for display
    {
      regen_percentage: regen_percentage,
      regen_time_percentage: total_regen_time > 0 ?
        (total_regen_time.to_f / (total_regen_time + total_consumption_time) * 100).round(2) : 0,
      total_samples: telemetries.count
    }
  end

  private

  def self.time_range_for_period(period)
    case period
    when :day
      1.day.ago..Time.current
    when :week
      1.week.ago..Time.current
    when :month
      1.month.ago..Time.current
    when :year
      1.year.ago..Time.current
    else
      1.week.ago..Time.current
    end
  end

  def self.interval_for_period(period)
    case period
    when :day
      1.hour
    when :week
      1.day
    when :month
      1.day
    when :year
      1.week
    else
      1.day
    end
  end

  def self.format_date_for_period(date, period)
    case period
    when :day
      date.strftime("%H:%M")
    when :week, :month
      date.strftime("%b %d")
    when :year
      date.strftime("%b %Y")
    else
      date.strftime("%b %d")
    end
  end

  def self.group_by_time_interval(trips, interval, time_range)
    result = {}

    # Initialize all intervals with zero values
    current_time = time_range.begin
    while current_time <= time_range.end
      result[current_time.beginning_of_hour] = { count: 0, distance: 0, duration: 0, avg_speed: 0 }
      current_time += interval
    end

    # Fill in actual data
    trips.each do |trip|
      interval_key = (trip.started_at.to_i / interval.to_i) * interval.to_i
      interval_time = Time.at(interval_key).beginning_of_hour

      result[interval_time] ||= { count: 0, distance: 0, duration: 0, avg_speed: 0 }
      result[interval_time][:count] += 1
      result[interval_time][:distance] += trip.distance.to_f

      if trip.ended_at && trip.started_at
        duration = (trip.ended_at - trip.started_at).to_f
        result[interval_time][:duration] += duration
      end

      result[interval_time][:avg_speed] = trip.avg_speed if trip.avg_speed && trip.avg_speed > result[interval_time][:avg_speed]
    end

    # Sort by time
    result.sort.to_h
  end

  def self.group_telemetry_by_interval(telemetries, interval, time_range)
    result = {}

    # Initialize all intervals with zero values
    current_time = time_range.begin
    while current_time <= time_range.end
      result[current_time.beginning_of_hour] = {
        battery0_level: 0,
        battery1_level: 0,
        estimated_range: 0,
        count: 0
      }
      current_time += interval
    end

    # Fill in actual data
    telemetries.each do |telemetry|
      interval_key = (telemetry.created_at.to_i / interval.to_i) * interval.to_i
      interval_time = Time.at(interval_key).beginning_of_hour

      result[interval_time] ||= {
        battery0_level: 0,
        battery1_level: 0,
        estimated_range: 0,
        count: 0
      }

      # Only count if we have battery data
      if telemetry.battery0_level || telemetry.battery1_level
        result[interval_time][:battery0_level] += telemetry.battery0_level.to_f
        result[interval_time][:battery1_level] += telemetry.battery1_level.to_f
        result[interval_time][:count] += 1
      end
    end

    # Calculate averages
    result.each do |time, data|
      if data[:count] > 0
        data[:battery0_level] = (data[:battery0_level] / data[:count]).round(2)
        data[:battery1_level] = (data[:battery1_level] / data[:count]).round(2)

        # Calculate estimated range based on battery levels
        # Assuming 40km range per 100% battery as mentioned in the Scooter model
        combined_battery = [ data[:battery0_level], data[:battery1_level] ].compact.sum
        data[:estimated_range] = combined_battery * 40.0 / 100.0
      end
    end

    # Sort by time
    result.sort.to_h
  end
end
