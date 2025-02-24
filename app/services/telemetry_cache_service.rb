class TelemetryCacheService
  CACHE_EXPIRY = 1.hour
  RECENT_TELEMETRY_LIMIT = 100
  DAILY_STATS_KEY = "scooter:%{scooter_id}:daily_stats:%{date}"
  RECENT_TELEMETRY_KEY = "scooter:%{scooter_id}:recent_telemetry"
  BATTERY_HISTORY_KEY = "scooter:%{scooter_id}:battery_history:%{period}"
  ODOMETER_HISTORY_KEY = "scooter:%{scooter_id}:odometer_history:%{period}"

  class << self
    def get_daily_stats(scooter_id, date = Date.today)
      key = DAILY_STATS_KEY % { scooter_id: scooter_id, date: date.to_s }

      Rails.cache.fetch(key, expires_in: CACHE_EXPIRY) do
        scooter = Scooter.find(scooter_id)
        start_time = date.beginning_of_day
        end_time = date.end_of_day

        telemetries = scooter.telemetries.where(created_at: start_time..end_time)

        {
          date: date.to_s,
          telemetry_count: telemetries.count,
          max_speed: telemetries.maximum(:speed) || 0,
          avg_speed: telemetries.average(:speed) || 0,
          distance_traveled: calculate_distance_traveled(telemetries),
          battery_drain: calculate_battery_drain(telemetries),
          updated_at: Time.current
        }
      end
    end

    def get_recent_telemetry(scooter_id)
      key = RECENT_TELEMETRY_KEY % { scooter_id: scooter_id }

      Rails.cache.fetch(key, expires_in: 5.minutes) do
        scooter = Scooter.find(scooter_id)
        scooter.telemetries.recent.limit(RECENT_TELEMETRY_LIMIT).map do |telemetry|
          {
            id: telemetry.id,
            created_at: telemetry.created_at,
            state: telemetry.state,
            speed: telemetry.speed,
            odometer: telemetry.odometer,
            battery0_level: telemetry.battery0_level,
            battery1_level: telemetry.battery1_level,
            lat: telemetry.lat,
            lng: telemetry.lng
          }
        end
      end
    end

    def get_battery_history(scooter_id, period = :week)
      key = BATTERY_HISTORY_KEY % { scooter_id: scooter_id, period: period }

      Rails.cache.fetch(key, expires_in: cache_expiry_for_period(period)) do
        scooter = Scooter.find(scooter_id)
        range = date_range_for_period(period)

        # Get one reading per day (or hour for day period)
        if period == :day
          group_by = "strftime('%Y-%m-%d %H', telemetries.created_at)"
          format = "%Y-%m-%d %H"
        else
          group_by = "strftime('%Y-%m-%d', telemetries.created_at)"
          format = "%Y-%m-%d"
        end

        telemetries = scooter.telemetries
          .where(created_at: range)
          .group(group_by)
          .select("
            strftime('#{format}', telemetries.created_at) as time_period,
            AVG(battery0_level) as avg_battery0,
            AVG(battery1_level) as avg_battery1
          ")
          .order("time_period ASC")

        telemetries.map do |t|
          {
            time_period: t.time_period,
            battery0: t.avg_battery0.to_f.round(2),
            battery1: t.avg_battery1.to_f.round(2),
            combined: ((t.avg_battery0.to_f + t.avg_battery1.to_f) / 2).round(2)
          }
        end
      end
    end

    def get_odometer_history(scooter_id, period = :month)
      key = ODOMETER_HISTORY_KEY % { scooter_id: scooter_id, period: period }

      Rails.cache.fetch(key, expires_in: cache_expiry_for_period(period)) do
        scooter = Scooter.find(scooter_id)
        range = date_range_for_period(period)

        # Get one reading per day (or hour for day period)
        if period == :day
          group_by = "strftime('%Y-%m-%d %H', telemetries.created_at)"
          format = "%Y-%m-%d %H"
        else
          group_by = "strftime('%Y-%m-%d', telemetries.created_at)"
          format = "%Y-%m-%d"
        end

        telemetries = scooter.telemetries
          .where(created_at: range)
          .group(group_by)
          .select("
            strftime('#{format}', telemetries.created_at) as time_period,
            MAX(odometer) as max_odometer
          ")
          .order("time_period ASC")

        telemetries.map do |t|
          {
            time_period: t.time_period,
            odometer: t.max_odometer.to_f.round(2)
          }
        end
      end
    end

    def invalidate_cache_for_scooter(scooter_id)
      # Invalidate daily stats for today
      key = DAILY_STATS_KEY % { scooter_id: scooter_id, date: Date.today.to_s }
      Rails.cache.delete(key)

      # Invalidate recent telemetry
      key = RECENT_TELEMETRY_KEY % { scooter_id: scooter_id }
      Rails.cache.delete(key)

      # Invalidate battery history for all periods
      [ :day, :week, :month, :year ].each do |period|
        key = BATTERY_HISTORY_KEY % { scooter_id: scooter_id, period: period }
        Rails.cache.delete(key)
      end

      # Invalidate odometer history for all periods
      [ :day, :week, :month, :year ].each do |period|
        key = ODOMETER_HISTORY_KEY % { scooter_id: scooter_id, period: period }
        Rails.cache.delete(key)
      end
    end

    private

    def calculate_distance_traveled(telemetries)
      return 0 if telemetries.empty?

      # Get first and last odometer readings for the day
      first = telemetries.order(created_at: :asc).first
      last = telemetries.order(created_at: :desc).first

      return 0 unless first.odometer && last.odometer

      # Return distance in meters
      (last.odometer - first.odometer).round
    end

    def calculate_battery_drain(telemetries)
      return 0 if telemetries.empty?

      # Get first and last battery readings for the day
      first = telemetries.order(created_at: :asc).first
      last = telemetries.order(created_at: :desc).first

      first_combined = [ first.battery0_level.to_f, first.battery1_level.to_f ].sum
      last_combined = [ last.battery0_level.to_f, last.battery1_level.to_f ].sum

      # Return battery drain percentage
      (first_combined - last_combined).round(2)
    end

    def date_range_for_period(period)
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

    def cache_expiry_for_period(period)
      case period
      when :day
        15.minutes
      when :week
        1.hour
      when :month
        6.hours
      when :year
        1.day
      else
        1.hour
      end
    end
  end
end
