class LeaderboardService
  PERIODS = {
    current_week: 1.week,
    previous_week: 1.week,
    current_month: 1.month,
    previous_month: 1.month,
    all_time: nil
  }.freeze

  # Cache keys
  LEADERBOARD_CACHE_KEY = "leaderboard:%{period}:%{date}"
  USER_POSITION_CACHE_KEY = "leaderboard:user:%{user_id}:%{period}:%{date}"
  COMMUNITY_AVERAGES_CACHE_KEY = "leaderboard:community:%{period}:%{date}"

  # Returns leaderboard data for the specified period
  def self.generate_leaderboard(period = :week, limit = 100, date = Date.current)
    # Use caching for leaderboard data
    key = LEADERBOARD_CACHE_KEY % { period: period, date: date.to_s }

    Rails.cache.fetch(key, expires_in: cache_expiry_for_period(period)) do
      date_range = date_range_for_period(period, date)

    # Only include users who have opted in
    query = User.joins(:user_preference)
                .where(user_preferences: { leaderboard_opt_in: true })

    # Add trip data if we're filtering by date
    if date_range
      query = query.joins(trips: :scooter)
                  .where(trips: { started_at: date_range })
                  .where.not(trips: { ended_at: nil })
    else
      query = query.joins(trips: :scooter)
                  .where.not(trips: { ended_at: nil })
    end

    # Group and calculate totals
    # Join with telemetry directly to get access to speed data and odometer
    query = query.joins("LEFT JOIN telemetries AS start_telemetry ON start_telemetry.id = trips.start_telemetry_id")
                .joins("LEFT JOIN telemetries AS end_telemetry ON end_telemetry.id = trips.end_telemetry_id")
                .joins("LEFT JOIN telemetries ON telemetries.scooter_id = scooters.id")
                .where("telemetries.created_at BETWEEN trips.started_at AND trips.ended_at")

    # Use a CASE statement to prioritize odometer-based distance calculation
    leaderboard_data = query.group("users.id, user_preferences.leaderboard_display_name")
                           .select('users.id,
                                   user_preferences.leaderboard_display_name,
                                   SUM(
                                     CASE
                                       WHEN end_telemetry.odometer IS NOT NULL AND start_telemetry.odometer IS NOT NULL AND end_telemetry.odometer >= start_telemetry.odometer
                                       THEN end_telemetry.odometer - start_telemetry.odometer
                                       ELSE trips.distance
                                     END
                                   ) as total_distance,
                                   COUNT(DISTINCT trips.id) as trip_count,
                                   MAX(telemetries.speed) as max_speed')
                           .order("total_distance DESC")
                           .limit(limit)

      # Format the data for display
      leaderboard_data.map.with_index(1) do |entry, rank|
        {
          rank: rank,
          user_id: entry.id,
          display_name: entry.leaderboard_display_name,
          distance_km: (entry.total_distance.to_f / 1000).round(1),
          trip_count: entry.trip_count,
          max_speed: entry.max_speed
        }
      end
    end
  end

  # Returns a user's position on the leaderboard
  def self.user_position(user_id, period = :week, date = Date.current)
    # Use caching for user position data
    key = USER_POSITION_CACHE_KEY % { user_id: user_id, period: period, date: date.to_s }

    Rails.cache.fetch(key, expires_in: cache_expiry_for_period(period)) do
      leaderboard = generate_leaderboard(period, 1000, date) # Get a larger set to find position

      entry = leaderboard.find { |e| e[:user_id] == user_id }
      return nil unless entry

      {
        rank: entry[:rank],
        total_users: leaderboard.size,
        percentile: ((entry[:rank].to_f / leaderboard.size) * 100).round(1),
        distance_km: entry[:distance_km],
        trip_count: entry[:trip_count]
      }
    end
  end

  # Returns community average stats
  def self.community_averages(period = :week, date = Date.current)
    # Use caching for community averages data
    key = COMMUNITY_AVERAGES_CACHE_KEY % { period: period, date: date.to_s }

    Rails.cache.fetch(key, expires_in: cache_expiry_for_period(period)) do
      date_range = date_range_for_period(period, date)

      # Get global averages from opted-in users
      global_trips = Trip.joins(user: :user_preference)
                       .where(user_preferences: { leaderboard_opt_in: true })
      global_trips = global_trips.where(started_at: date_range) if date_range
      global_trips = global_trips.where.not(ended_at: nil)

      global_avg_distance = global_trips.average(:distance).to_f / 1000
      global_avg_trip_count = global_trips.count.to_f / User.joins(:user_preference)
                                                          .where(user_preferences: { leaderboard_opt_in: true })
                                                          .count

      # Get global telemetry data for average speed calculation
      global_telemetry = Telemetry.joins(scooter: { trips: { user: :user_preference } })
                                 .where(user_preferences: { leaderboard_opt_in: true })
                                 .where.not(trips: { ended_at: nil })
      global_telemetry = global_telemetry.where("telemetries.created_at BETWEEN trips.started_at AND trips.ended_at")
      global_telemetry = global_telemetry.where(trips: { started_at: date_range }) if date_range
      global_avg_speed = global_telemetry.average(:speed).to_f.round(1)

      {
        distance_km: global_avg_distance.round(1),
        trip_count: global_avg_trip_count.round(1),
        avg_speed: global_avg_speed
      }
    end
  end

  # Returns stats comparing the user to others
  def self.user_comparison(user_id, period = :week, date = Date.current)
    date_range = date_range_for_period(period, date)

    # Get user's data
    user_trips = Trip.where(user_id: user_id)
    user_trips = user_trips.where(started_at: date_range) if date_range
    user_trips = user_trips.where.not(ended_at: nil)

    user_distance = user_trips.sum(:distance).to_f / 1000
    user_trip_count = user_trips.count

    # Get user's telemetry data for average speed calculation
    user_telemetry = Telemetry.joins(scooter: :trips)
                             .where(trips: { user_id: user_id })
                             .where.not(trips: { ended_at: nil })
    user_telemetry = user_telemetry.where("telemetries.created_at BETWEEN trips.started_at AND trips.ended_at")
    user_telemetry = user_telemetry.where(trips: { started_at: date_range }) if date_range
    user_avg_speed = user_telemetry.average(:speed).to_f.round(1)

    # Get community averages
    global_average = community_averages(period, date)

    {
      user: {
        distance_km: user_distance.round(1),
        trip_count: user_trip_count,
        avg_speed: user_avg_speed
      },
      global_average: global_average,
      comparison: {
        distance_percent: global_average[:distance_km] > 0 ? ((user_distance / global_average[:distance_km]) * 100).round : 0,
        trip_count_percent: global_average[:trip_count] > 0 ? ((user_trip_count / global_average[:trip_count]) * 100).round : 0,
        speed_percent: global_average[:avg_speed] > 0 ? ((user_avg_speed / global_average[:avg_speed]) * 100).round : 0
      }
    }
  end

  private

  def self.date_range_for_period(period, date = Date.current)
    case period.to_sym
    when :current_week, :previous_week
      date.beginning_of_week..date.end_of_week
    when :current_month, :previous_month
      date.beginning_of_month..date.end_of_month
    when :all_time
      nil
    else
      date.beginning_of_week..date.end_of_week
    end
  end

  def self.cache_expiry_for_period(period)
    case period
    when :current_week, :previous_week
      6.hours
    when :current_month, :previous_month
      1.day
    when :all_time
      1.day
    else
      6.hours
    end
  end
end
