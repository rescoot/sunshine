class AchievementService
  # Check and update achievements for a user
  def self.check_achievements(user)
    # Ensure we have achievement definitions
    seed_achievements_if_needed

    # Check each achievement type
    check_distance_achievements(user)
    check_trip_achievements(user)
    check_duration_achievements(user)
    check_speed_achievements(user)
    check_ownership_achievements(user)
    check_special_achievements(user)

    # Return earned and in-progress achievements
    # For earned achievements, include both visible and secret achievements
    # For in-progress achievements, only include visible achievements
    {
      earned: user.user_achievements.earned.includes(:achievement_definition),
      in_progress: user.user_achievements.in_progress
                       .includes(:achievement_definition)
                       .where(achievement_definitions: { secret: false })
    }
  end

  # Get a user's total achievement points
  def self.total_points(user)
    user.user_achievements.earned.joins(:achievement_definition).sum("achievement_definitions.points")
  end

  # Get recently earned achievements
  def self.recent_achievements(user, limit = 5)
    user.user_achievements.earned.recent.includes(:achievement_definition).limit(limit)
  end

  # Get next achievements to earn
  def self.next_achievements(user, limit = 3)
    earned_ids = user.user_achievements.earned.pluck(:achievement_definition_id)

    # For each achievement type, find the next one to earn
    next_achievements = []

    AchievementDefinition::TYPES.keys.each do |type|
      # Find achievements of this type that haven't been earned yet
      # Only include visible achievements, not secret ones
      achievements = AchievementDefinition.by_type(type.to_s)
                                         .visible
                                         .where.not(id: earned_ids)
                                         .ordered_by_threshold

      # Add the first one (lowest threshold) if it exists
      next_achievements << achievements.first if achievements.any?
    end

    # Return the specified number of achievements
    next_achievements.compact.take(limit)
  end

  private

  def self.seed_achievements_if_needed
    AchievementDefinition.seed_default_achievements if AchievementDefinition.count.zero?
  end

  def self.check_distance_achievements(user)
    # Calculate total distance
    total_distance_meters = user.trips.where.not(ended_at: nil).sum(:distance)
    total_distance_km = total_distance_meters / 1000.0

    # Check each distance achievement
    AchievementDefinition.by_type("distance").ordered_by_threshold.each do |achievement|
      user_achievement = user.user_achievements.find_or_initialize_by(achievement_definition: achievement)
      user_achievement.progress = total_distance_km

      # Mark as earned if threshold is met
      if total_distance_km >= achievement.threshold && user_achievement.earned_at.nil?
        user_achievement.earned_at = Time.current
        notify_achievement_earned(user, achievement)
      end

      user_achievement.save!
    end
  end

  def self.check_trip_achievements(user)
    # Count completed trips
    trip_count = user.trips.where.not(ended_at: nil).count

    # Check each trip achievement
    AchievementDefinition.by_type("trips").ordered_by_threshold.each do |achievement|
      user_achievement = user.user_achievements.find_or_initialize_by(achievement_definition: achievement)
      user_achievement.progress = trip_count

      # Mark as earned if threshold is met
      if trip_count >= achievement.threshold && user_achievement.earned_at.nil?
        user_achievement.earned_at = Time.current
        notify_achievement_earned(user, achievement)
      end

      user_achievement.save!
    end
  end

  def self.check_duration_achievements(user)
    # Calculate total duration in hours
    total_duration_seconds = 0

    user.trips.where.not(ended_at: nil).each do |trip|
      total_duration_seconds += (trip.ended_at - trip.started_at) if trip.ended_at && trip.started_at
    end

    total_duration_hours = total_duration_seconds / 3600.0

    # Check each duration achievement
    AchievementDefinition.by_type("duration").ordered_by_threshold.each do |achievement|
      user_achievement = user.user_achievements.find_or_initialize_by(achievement_definition: achievement)
      user_achievement.progress = total_duration_hours

      # Mark as earned if threshold is met
      if total_duration_hours >= achievement.threshold && user_achievement.earned_at.nil?
        user_achievement.earned_at = Time.current
        notify_achievement_earned(user, achievement)
      end

      user_achievement.save!
    end
  end

  def self.check_speed_achievements(user)
    # Find maximum speed
    max_speed = user.trips.maximum(:avg_speed) || 0

    # Check each speed achievement
    AchievementDefinition.by_type("speed").ordered_by_threshold.each do |achievement|
      user_achievement = user.user_achievements.find_or_initialize_by(achievement_definition: achievement)
      user_achievement.progress = max_speed

      # Mark as earned if threshold is met
      if max_speed >= achievement.threshold && user_achievement.earned_at.nil?
        user_achievement.earned_at = Time.current
        notify_achievement_earned(user, achievement)
      end

      user_achievement.save!
    end
  end

  def self.check_ownership_achievements(user)
    # Count owned scooters
    scooter_count = user.user_scooters.where(role: "owner").count

    # Check each ownership achievement
    AchievementDefinition.by_type("ownership").ordered_by_threshold.each do |achievement|
      user_achievement = user.user_achievements.find_or_initialize_by(achievement_definition: achievement)
      user_achievement.progress = scooter_count

      # Mark as earned if threshold is met
      if scooter_count >= achievement.threshold && user_achievement.earned_at.nil?
        user_achievement.earned_at = Time.current
        notify_achievement_earned(user, achievement)
      end

      user_achievement.save!
    end
  end

  def self.check_special_achievements(user)
    # Night Owl achievement - Complete a trip between midnight and 4 AM
    night_owl = AchievementDefinition.find_by(name: "Night Owl")
    if night_owl
      # Use SQLite's strftime function to extract hour
      night_trips_count = user.trips.where.not(ended_at: nil)
                             .where("strftime('%H', started_at) BETWEEN '00' AND '03'")
                             .count

      user_achievement = user.user_achievements.find_or_initialize_by(achievement_definition: night_owl)
      user_achievement.progress = night_trips_count

      if night_trips_count >= night_owl.threshold && user_achievement.earned_at.nil?
        user_achievement.earned_at = Time.current
        notify_achievement_earned(user, night_owl)
      end

      user_achievement.save!
    end

    # Weekend Warrior achievement - Complete trips on 5 consecutive weekends
    weekend_warrior = AchievementDefinition.find_by(name: "Weekend Warrior")
    if weekend_warrior
      # Get all weekend trips - SQLite uses 0 for Sunday and 6 for Saturday
      weekend_trips = user.trips.where.not(ended_at: nil)
                          .where("strftime('%w', started_at) IN ('0', '6')") # 0 = Sunday, 6 = Saturday
                          .order(started_at: :asc)

      # Count consecutive weekends
      consecutive_weekends = 0
      current_weekend = nil
      max_consecutive = 0

      weekend_trips.each do |trip|
        trip_weekend = trip.started_at.beginning_of_week(:sunday)

        if current_weekend.nil? || trip_weekend > current_weekend
          if current_weekend.nil? || trip_weekend == current_weekend + 7.days
            consecutive_weekends += 1
          else
            consecutive_weekends = 1
          end

          current_weekend = trip_weekend
          max_consecutive = [ max_consecutive, consecutive_weekends ].max
        end
      end

      user_achievement = user.user_achievements.find_or_initialize_by(achievement_definition: weekend_warrior)
      user_achievement.progress = max_consecutive

      if max_consecutive >= weekend_warrior.threshold && user_achievement.earned_at.nil?
        user_achievement.earned_at = Time.current
        notify_achievement_earned(user, weekend_warrior)
      end

      user_achievement.save!
    end

    # Explorer achievement - Visit 10 different neighborhoods in your city
    # Quantize locations and ensure a minimum distance between them (5km)
    explorer = AchievementDefinition.find_by(name: "Explorer")
    if explorer
      # Get all completed trips with valid coordinates
      trips_with_coords = user.trips.where.not(ended_at: nil)
                             .where.not(start_lat: nil, start_lng: nil)
                             .to_a

      # Quantize locations to reduce GPS jitter (round to ~100m precision)
      # and ensure minimum distance between locations
      significant_locations = []

      trips_with_coords.each do |trip|
        # Quantize the location (round to 3 decimal places, approximately 100m precision)
        quantized_lat = trip.start_lat.to_f.round(3)
        quantized_lng = trip.start_lng.to_f.round(3)

        # Check if this location is far enough from all existing significant locations
        is_significant = true

        significant_locations.each do |existing_loc|
          distance = calculate_distance_between(
            quantized_lat, quantized_lng,
            existing_loc[0], existing_loc[1]
          )

          # If distance is less than 5km, it's not a significant new location
          if distance && distance < 5
            is_significant = false
            break
          end
        end

        # Add to significant locations if it passes the distance check
        significant_locations << [ quantized_lat, quantized_lng ] if is_significant
      end

      unique_locations = significant_locations.size

      user_achievement = user.user_achievements.find_or_initialize_by(achievement_definition: explorer)
      user_achievement.progress = unique_locations

      if unique_locations >= explorer.threshold && user_achievement.earned_at.nil?
        user_achievement.earned_at = Time.current
        notify_achievement_earned(user, explorer)
      end

      user_achievement.save!
    end

    # All-Seasons Rider achievement - Complete at least one trip in each month of the year
    all_seasons = AchievementDefinition.find_by(name: "All-Seasons Rider")
    if all_seasons
      # Get distinct months using Ruby
      # This is more SQLite-friendly than trying to do it in the query
      months = Set.new
      user.trips.where.not(ended_at: nil).each do |trip|
        if trip.started_at
          # Extract month (1-12)
          month = trip.started_at.month
          months.add(month)
        end
      end

      months_count = months.size

      user_achievement = user.user_achievements.find_or_initialize_by(achievement_definition: all_seasons)
      user_achievement.progress = months_count

      if months_count >= all_seasons.threshold && user_achievement.earned_at.nil?
        user_achievement.earned_at = Time.current
        notify_achievement_earned(user, all_seasons)
      end

      user_achievement.save!
    end

    # All-Weather Rider achievement - Placeholder for future implementation
    # This will be implemented in the future with actual weather data
    all_weather = AchievementDefinition.find_by(name: "All-Weather Rider")
    if all_weather
      # Placeholder implementation - will be replaced with actual weather data in the future
      user_achievement = user.user_achievements.find_or_initialize_by(achievement_definition: all_weather)
      user_achievement.progress = 0 # No progress until implemented with real weather data
      user_achievement.save!
    end

    # Battery Master achievement - Complete a trip with less than 10% battery remaining, starting with at least 25% battery
    battery_master = AchievementDefinition.find_by(name: "Battery Master")
    if battery_master
      # Count trips that meet the battery criteria
      # - Start with at least 25% battery
      # - End with less than 10% battery
      qualifying_trips = user.trips.completed
                             .with_telemetry
                             .with_sufficient_start_battery
                             .with_low_end_battery
                             .count

      user_achievement = user.user_achievements.find_or_initialize_by(achievement_definition: battery_master)
      user_achievement.progress = qualifying_trips

      if qualifying_trips >= battery_master.threshold && user_achievement.earned_at.nil?
        user_achievement.earned_at = Time.current
        notify_achievement_earned(user, battery_master)
      end

      user_achievement.save!
    end
  end

  def self.calculate_distance_between(lat1, lng1, lat2, lng2)
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

  def self.notify_achievement_earned(user, achievement)
    # Only notify if user has opted in to notifications
    return unless user.user_preference&.receive_achievement_notifications

    # Send email notification
    UserMailer.achievement_earned(user, achievement).deliver_later

    # Could also add in-app notifications, push notifications, etc.
  end
end
