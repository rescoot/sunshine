class LeaderboardService
  PERIODS = {
    day: 1.day,
    week: 1.week,
    month: 1.month,
    all_time: nil
  }.freeze

  # Returns leaderboard data for the specified period
  def self.generate_leaderboard(period = :week, limit = 100)
    date_range = date_range_for_period(period)

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
    leaderboard_data = query.group("users.id, user_preferences.leaderboard_display_name")
                           .select('users.id,
                                   user_preferences.leaderboard_display_name,
                                   SUM(trips.distance) as total_distance,
                                   COUNT(DISTINCT trips.id) as trip_count,
                                   MAX(trips.avg_speed) as max_speed')
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

  # Returns a user's position on the leaderboard
  def self.user_position(user_id, period = :week)
    leaderboard = generate_leaderboard(period, 1000) # Get a larger set to find position

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

  # Returns stats comparing the user to others
  def self.user_comparison(user_id, period = :week)
    date_range = date_range_for_period(period)

    # Get user's data
    user_data = Trip.where(user_id: user_id)
    user_data = user_data.where(started_at: date_range) if date_range
    user_data = user_data.where.not(ended_at: nil)

    user_distance = user_data.sum(:distance).to_f / 1000
    user_trip_count = user_data.count
    user_avg_speed = user_data.average(:avg_speed).to_f.round(1)

    # Get global averages from opted-in users
    global_data = Trip.joins(user: :user_preference)
                     .where(user_preferences: { leaderboard_opt_in: true })
    global_data = global_data.where(started_at: date_range) if date_range
    global_data = global_data.where.not(ended_at: nil)

    global_avg_distance = global_data.average(:distance).to_f / 1000
    global_avg_trip_count = global_data.count.to_f / User.joins(:user_preference)
                                                        .where(user_preferences: { leaderboard_opt_in: true })
                                                        .count
    global_avg_speed = global_data.average(:avg_speed).to_f.round(1)

    {
      user: {
        distance_km: user_distance.round(1),
        trip_count: user_trip_count,
        avg_speed: user_avg_speed
      },
      global_average: {
        distance_km: global_avg_distance.round(1),
        trip_count: global_avg_trip_count.round(1),
        avg_speed: global_avg_speed
      },
      comparison: {
        distance_percent: global_avg_distance > 0 ? ((user_distance / global_avg_distance) * 100).round : 0,
        trip_count_percent: global_avg_trip_count > 0 ? ((user_trip_count / global_avg_trip_count) * 100).round : 0,
        speed_percent: global_avg_speed > 0 ? ((user_avg_speed / global_avg_speed) * 100).round : 0
      }
    }
  end

  private

  def self.date_range_for_period(period)
    case period.to_sym
    when :day
      Time.current.beginning_of_day..Time.current.end_of_day
    when :week
      Time.current.beginning_of_week..Time.current.end_of_week
    when :month
      Time.current.beginning_of_month..Time.current.end_of_month
    when :all_time
      nil
    else
      Time.current.beginning_of_week..Time.current.end_of_week
    end
  end
end
