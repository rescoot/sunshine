class AchievementService
  CACHE_EXPIRY = 1.hour

  # Check and update achievements for a user
  # This method is now primarily used by the background job
  def self.check_achievements(user)
    process_and_cache_achievements(user)
  end

  # Process achievements and store them in cache
  # Returns the processed achievements
  def self.process_and_cache_achievements(user)
    # Ensure we have achievement definitions
    seed_achievements_if_needed

    # Check each achievement type
    check_distance_achievements(user)
    check_trip_achievements(user)
    check_duration_achievements(user)
    check_speed_achievements(user)
    check_ownership_achievements(user)
    check_membership_duration_achievements(user)
    check_special_achievements(user)

    # Prepare the achievement data
    achievements = {
      earned: user.user_achievements.earned.includes(:achievement_definition),
      in_progress: user.user_achievements.in_progress
                       .includes(:achievement_definition)
                       .where(achievement_definitions: { secret: false })
    }

    # Cache the achievement data
    cache_achievements(user, achievements)

    # Return the achievements
    achievements
  end

  # Get achievements for a user, using cache when available
  def self.get_achievements(user)
    # Try to get achievements from cache
    cached = get_cached_achievements(user)
    return cached if cached.present?

    # If not in cache, process and cache them
    process_and_cache_achievements(user)
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
    in_progress_ids = user.user_achievements.in_progress.pluck(:achievement_definition_id)

    # Exclude both earned and in-progress achievements
    excluded_ids = earned_ids + in_progress_ids

    # Get all visible achievements that haven't been earned or started yet
    available_achievements = AchievementDefinition.visible
                                                 .where.not(id: excluded_ids)
                                                 .ordered_by_threshold

    # Randomly select achievements up to the limit
    available_achievements.sample(limit)
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
    # Find maximum speed from telemetry data
    max_speed = 0

    # Get all user's scooters
    user_scooters = user.scooters.pluck(:id)

    # Find maximum speed across all telemetry data for user's scooters
    if user_scooters.any?
      max_telemetry_speed = Telemetry.where(scooter_id: user_scooters).maximum(:speed) || 0
      max_speed = max_telemetry_speed
    end

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

  def self.check_membership_duration_achievements(user)
    # Calculate days since user registration
    days_as_member = (Date.current - user.created_at.to_date).to_i

    # Find membership duration achievements
    membership_achievements = AchievementDefinition.where("name LIKE ?", "%Member%").ordered_by_threshold

    # Check each membership achievement
    membership_achievements.each do |achievement|
      user_achievement = user.user_achievements.find_or_initialize_by(achievement_definition: achievement)
      user_achievement.progress = days_as_member

      # Mark as earned if threshold is met
      if days_as_member >= achievement.threshold && user_achievement.earned_at.nil?
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

    # Early Bird achievement - Complete 5 trips that start before 7 AM
    early_bird = AchievementDefinition.find_by(name: "Early Bird")
    if early_bird
      # Count trips that start before 7 AM
      early_trips_count = user.trips.where.not(ended_at: nil)
                             .where("strftime('%H', started_at) < '07'")
                             .count

      user_achievement = user.user_achievements.find_or_initialize_by(achievement_definition: early_bird)
      user_achievement.progress = early_trips_count

      if early_trips_count >= early_bird.threshold && user_achievement.earned_at.nil?
        user_achievement.earned_at = Time.current
        notify_achievement_earned(user, early_bird)
      end

      user_achievement.save!
    end

    # Night Rider achievement - Complete 10 trips between 8 PM and midnight
    night_rider = AchievementDefinition.find_by(name: "Night Rider")
    if night_rider
      # Count trips that start between 8 PM and midnight
      night_trips_count = user.trips.where.not(ended_at: nil)
                             .where("strftime('%H', started_at) BETWEEN '20' AND '23'")
                             .count

      user_achievement = user.user_achievements.find_or_initialize_by(achievement_definition: night_rider)
      user_achievement.progress = night_trips_count

      if night_trips_count >= night_rider.threshold && user_achievement.earned_at.nil?
        user_achievement.earned_at = Time.current
        notify_achievement_earned(user, night_rider)
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

    # Rush Hour Hero achievement
    rush_hour_hero = AchievementDefinition.find_by(name: "Rush Hour Hero")
    if rush_hour_hero
      # Count trips during peak hours (7-9 AM or 4-6 PM)
      rush_hour_trips_count = user.trips.where.not(ended_at: nil)
                                 .where("(strftime('%H', started_at) BETWEEN '07' AND '08') OR (strftime('%H', started_at) BETWEEN '16' AND '17')")
                                 .count

      user_achievement = user.user_achievements.find_or_initialize_by(achievement_definition: rush_hour_hero)
      user_achievement.progress = rush_hour_trips_count

      if rush_hour_trips_count >= rush_hour_hero.threshold && user_achievement.earned_at.nil?
        user_achievement.earned_at = Time.current
        notify_achievement_earned(user, rush_hour_hero)
      end

      user_achievement.save!
    end

    # Consistent Commuter achievement
    consistent_commuter = AchievementDefinition.find_by(name: "Consistent Commuter")
    if consistent_commuter
      # Get all weekday trips - SQLite uses 0 for Sunday and 6 for Saturday
      weekday_trips = user.trips.where.not(ended_at: nil)
                          .where("strftime('%w', started_at) BETWEEN '1' AND '5'") # 1-5 = Monday-Friday
                          .order(started_at: :asc)

      # Count consecutive weekdays
      consecutive_weekdays = 0
      current_day = nil
      max_consecutive = 0

      weekday_trips.each do |trip|
        trip_day = trip.started_at.to_date

        if current_day.nil? || trip_day > current_day
          if current_day.nil? || trip_day == current_day + 1.day
            consecutive_weekdays += 1
          else
            consecutive_weekdays = 1
          end

          current_day = trip_day
          max_consecutive = [ max_consecutive, consecutive_weekdays ].max
        end
      end

      user_achievement = user.user_achievements.find_or_initialize_by(achievement_definition: consistent_commuter)
      user_achievement.progress = max_consecutive

      if max_consecutive >= consistent_commuter.threshold && user_achievement.earned_at.nil?
        user_achievement.earned_at = Time.current
        notify_achievement_earned(user, consistent_commuter)
      end

      user_achievement.save!
    end

    # Long Distance Relationship achievement
    long_distance = AchievementDefinition.find_by(name: "Long Distance Relationship")
    if long_distance
      # Check if any trip is longer than 15 km
      long_trips_count = user.trips.where.not(ended_at: nil)
                            .where("distance >= ?", 15000) # 15 km in meters
                            .count

      user_achievement = user.user_achievements.find_or_initialize_by(achievement_definition: long_distance)
      user_achievement.progress = long_trips_count

      if long_trips_count >= long_distance.threshold && user_achievement.earned_at.nil?
        user_achievement.earned_at = Time.current
        notify_achievement_earned(user, long_distance)
      end

      user_achievement.save!
    end

    # Marathon Rider achievement
    marathon_rider = AchievementDefinition.find_by(name: "Marathon Rider")
    if marathon_rider
      # Check if any trip lasts more than 45 minutes
      long_duration_trips = user.trips.where.not(ended_at: nil)
                               .where("(julianday(ended_at) - julianday(started_at)) * 24 * 60 >= ?", 45) # 45 minutes
                               .count

      user_achievement = user.user_achievements.find_or_initialize_by(achievement_definition: marathon_rider)
      user_achievement.progress = long_duration_trips

      if long_duration_trips >= marathon_rider.threshold && user_achievement.earned_at.nil?
        user_achievement.earned_at = Time.current
        notify_achievement_earned(user, marathon_rider)
      end

      user_achievement.save!
    end

    # Range Optimizer achievement
    range_optimizer = AchievementDefinition.find_by(name: "Range Optimizer")
    if range_optimizer
      # Find trips with distance > 35 km
      long_range_trips = user.trips.where.not(ended_at: nil)
                             .where("distance >= ?", 35000) # 35 km in meters
                             .count

      user_achievement = user.user_achievements.find_or_initialize_by(achievement_definition: range_optimizer)
      user_achievement.progress = long_range_trips

      if long_range_trips >= range_optimizer.threshold && user_achievement.earned_at.nil?
        user_achievement.earned_at = Time.current
        notify_achievement_earned(user, range_optimizer)
      end

      user_achievement.save!
    end

    # Battery Balancer achievement
    battery_balancer = AchievementDefinition.find_by(name: "Battery Balancer")
    if battery_balancer
      # Count trips where both batteries are within 5% of each other
      balanced_trips_count = 0

      user.trips.where.not(ended_at: nil).each do |trip|
        # Get the start telemetry
        if trip.start_telemetry &&
           trip.start_telemetry.battery0_level &&
           trip.start_telemetry.battery1_level

          # Check if batteries are within 5% of each other
          battery_diff = (trip.start_telemetry.battery0_level - trip.start_telemetry.battery1_level).abs
          balanced_trips_count += 1 if battery_diff <= 5
        end
      end

      user_achievement = user.user_achievements.find_or_initialize_by(achievement_definition: battery_balancer)
      user_achievement.progress = balanced_trips_count

      if balanced_trips_count >= battery_balancer.threshold && user_achievement.earned_at.nil?
        user_achievement.earned_at = Time.current
        notify_achievement_earned(user, battery_balancer)
      end

      user_achievement.save!
    end

    # Charge Planner achievement
    charge_planner = AchievementDefinition.find_by(name: "Charge Planner")
    if charge_planner
      # Count trips ending with between 10-20% battery remaining
      planned_trips_count = 0

      user.trips.where.not(ended_at: nil).each do |trip|
        # Get the end telemetry
        if trip.end_telemetry &&
           trip.end_telemetry.battery0_level &&
           trip.end_telemetry.battery1_level

          # Calculate total battery percentage
          total_battery = trip.end_telemetry.battery0_level + trip.end_telemetry.battery1_level

          # Check if total battery is between 10-20%
          planned_trips_count += 1 if total_battery >= 10 && total_battery <= 20
        end
      end

      user_achievement = user.user_achievements.find_or_initialize_by(achievement_definition: charge_planner)
      user_achievement.progress = planned_trips_count

      if planned_trips_count >= charge_planner.threshold && user_achievement.earned_at.nil?
        user_achievement.earned_at = Time.current
        notify_achievement_earned(user, charge_planner)
      end

      user_achievement.save!
    end

    # Full Potential achievement
    full_potential = AchievementDefinition.find_by(name: "Full Potential")
    if full_potential
      # Count trips starting with 100% battery on both batteries
      full_battery_trips = 0

      user.trips.where.not(ended_at: nil).each do |trip|
        # Get the start telemetry
        if trip.start_telemetry &&
           trip.start_telemetry.battery0_level &&
           trip.start_telemetry.battery1_level

          # Check if both batteries are at 100%
          full_battery_trips += 1 if trip.start_telemetry.battery0_level >= 99 &&
                                     trip.start_telemetry.battery1_level >= 99
        end
      end

      user_achievement = user.user_achievements.find_or_initialize_by(achievement_definition: full_potential)
      user_achievement.progress = full_battery_trips

      if full_battery_trips >= full_potential.threshold && user_achievement.earned_at.nil?
        user_achievement.earned_at = Time.current
        notify_achievement_earned(user, full_potential)
      end

      user_achievement.save!
    end

    # Leaderboard Champion achievements
    check_leaderboard_achievements(user)

    # Achievement Hunter achievement
    achievement_hunter = AchievementDefinition.find_by(name: "Achievement Hunter")
    if achievement_hunter
      # Count earned achievements
      earned_achievements_count = user.user_achievements.earned.count

      user_achievement = user.user_achievements.find_or_initialize_by(achievement_definition: achievement_hunter)
      user_achievement.progress = earned_achievements_count

      if earned_achievements_count >= achievement_hunter.threshold && user_achievement.earned_at.nil?
        user_achievement.earned_at = Time.current
        notify_achievement_earned(user, achievement_hunter)
      end

      user_achievement.save!
    end

    # Winter Warrior achievement
    winter_warrior = AchievementDefinition.find_by(name: "Winter Warrior")
    if winter_warrior
      # Count trips when temperature is below 5°C
      cold_trips_count = 0

      user.trips.where.not(ended_at: nil).each do |trip|
        # Get the start telemetry
        if trip.start_telemetry && trip.start_telemetry.temperature
          # Check if temperature is below 5°C
          cold_trips_count += 1 if trip.start_telemetry.temperature < 5
        end
      end

      user_achievement = user.user_achievements.find_or_initialize_by(achievement_definition: winter_warrior)
      user_achievement.progress = cold_trips_count

      if cold_trips_count >= winter_warrior.threshold && user_achievement.earned_at.nil?
        user_achievement.earned_at = Time.current
        notify_achievement_earned(user, winter_warrior)
      end

      user_achievement.save!
    end

    # Summer Cruiser achievement
    summer_cruiser = AchievementDefinition.find_by(name: "Summer Cruiser")
    if summer_cruiser
      # Count trips when temperature is above 25°C
      hot_trips_count = 0

      user.trips.where.not(ended_at: nil).each do |trip|
        # Get the start telemetry
        if trip.start_telemetry && trip.start_telemetry.temperature
          # Check if temperature is above 25°C
          hot_trips_count += 1 if trip.start_telemetry.temperature > 25
        end
      end

      user_achievement = user.user_achievements.find_or_initialize_by(achievement_definition: summer_cruiser)
      user_achievement.progress = hot_trips_count

      if hot_trips_count >= summer_cruiser.threshold && user_achievement.earned_at.nil?
        user_achievement.earned_at = Time.current
        notify_achievement_earned(user, summer_cruiser)
      end

      user_achievement.save!
    end

    # Anniversary Celebration achievement
    anniversary_celebration = AchievementDefinition.find_by(name: "Anniversary Celebration")
    if anniversary_celebration
      # Get user's first trip
      first_trip = user.trips.where.not(ended_at: nil).order(started_at: :asc).first

      if first_trip && first_trip.started_at < 11.months.ago
        # Check if any trip was completed on the anniversary of the first trip
        anniversary_trips = 0

        user.trips.where.not(ended_at: nil).each do |trip|
          # Check if the trip is on the anniversary of the first trip
          if trip.started_at.month == first_trip.started_at.month &&
             trip.started_at.day == first_trip.started_at.day &&
             trip.started_at.year > first_trip.started_at.year

            anniversary_trips += 1
          end
        end

        user_achievement = user.user_achievements.find_or_initialize_by(achievement_definition: anniversary_celebration)
        user_achievement.progress = anniversary_trips

        if anniversary_trips >= anniversary_celebration.threshold && user_achievement.earned_at.nil?
          user_achievement.earned_at = Time.current
          notify_achievement_earned(user, anniversary_celebration)
        end

        user_achievement.save!
      end
    end

    # Milestone Marker achievement
    milestone_marker = AchievementDefinition.find_by(name: "Milestone Marker")
    if milestone_marker
      # Count total completed trips
      trip_count = user.trips.where.not(ended_at: nil).count

      user_achievement = user.user_achievements.find_or_initialize_by(achievement_definition: milestone_marker)
      user_achievement.progress = trip_count

      if trip_count >= milestone_marker.threshold && user_achievement.earned_at.nil?
        user_achievement.earned_at = Time.current
        notify_achievement_earned(user, milestone_marker)
      end

      user_achievement.save!
    end

    # Steady Sailor achievement - requires analyzing telemetry data for smooth acceleration/deceleration
    steady_sailor = AchievementDefinition.find_by(name: "Steady Sailor")
    if steady_sailor
      # This is a more complex achievement that requires analyzing telemetry data
      # We'll implement a simplified version for now
      # In a real implementation, we would analyze consecutive telemetry readings to detect sudden changes in speed

      # For now, we'll count trips with a relatively constant speed (low standard deviation)
      smooth_trips = 0

      user.trips.where.not(ended_at: nil).each do |trip|
        # Get all telemetries for this trip
        trip_telemetries = trip.scooter.telemetries
                               .where("created_at BETWEEN ? AND ?", trip.started_at, trip.ended_at)
                               .order(created_at: :asc)
                               .to_a

        # Need at least 10 telemetry readings to analyze
        if trip_telemetries.size >= 10
          # Extract speed values
          speeds = trip_telemetries.map(&:speed).compact

          if speeds.size >= 10
            # Calculate standard deviation of speed
            mean = speeds.sum / speeds.size.to_f
            variance = speeds.sum { |s| (s - mean) ** 2 } / speeds.size.to_f
            std_dev = Math.sqrt(variance)

            # If standard deviation is low, consider it a smooth trip
            smooth_trips += 1 if std_dev < 5 # threshold for "smooth" riding
          end
        end
      end

      user_achievement = user.user_achievements.find_or_initialize_by(achievement_definition: steady_sailor)
      user_achievement.progress = smooth_trips

      if smooth_trips >= steady_sailor.threshold && user_achievement.earned_at.nil?
        user_achievement.earned_at = Time.current
        notify_achievement_earned(user, steady_sailor)
      end

      user_achievement.save!
    end

    # Eco Rider achievement - Achieve 20% regeneration efficiency on 5 trips
    eco_rider = AchievementDefinition.find_by(name: "Eco Rider")
    if eco_rider
      # Count trips with at least 20% regeneration efficiency
      efficient_trips = 0

      user.trips.where.not(ended_at: nil).each do |trip|
        # Get all telemetries for this trip with motor current data
        trip_telemetries = trip.scooter.telemetries
                               .where("created_at BETWEEN ? AND ?", trip.started_at, trip.ended_at)
                               .where.not(motor_current: nil)
                               .to_a

        if trip_telemetries.size >= 10 # Need enough data points
          # Calculate regeneration metrics
          total_regen_current = 0
          total_consumption_current = 0

          trip_telemetries.each do |telemetry|
            if telemetry.motor_current < 0 # Regenerating
              total_regen_current += telemetry.motor_current.abs
            else # Consuming
              total_consumption_current += telemetry.motor_current
            end
          end

          # Calculate regeneration efficiency
          if total_consumption_current > 0
            regen_efficiency = (total_regen_current / total_consumption_current * 100).round(2)
            efficient_trips += 1 if regen_efficiency >= 20
          end
        end
      end

      user_achievement = user.user_achievements.find_or_initialize_by(achievement_definition: eco_rider)
      user_achievement.progress = efficient_trips

      if efficient_trips >= eco_rider.threshold && user_achievement.earned_at.nil?
        user_achievement.earned_at = Time.current
        notify_achievement_earned(user, eco_rider)
      end

      user_achievement.save!
    end

    # Acceleration Master achievement - Reach 25 km/h from standstill in under 10 seconds
    acceleration_master = AchievementDefinition.find_by(name: "Acceleration Master")
    if acceleration_master
      # Count trips with rapid acceleration
      rapid_acceleration_trips = 0

      user.trips.where.not(ended_at: nil).each do |trip|
        # Get all telemetries for this trip
        trip_telemetries = trip.scooter.telemetries
                               .where("created_at BETWEEN ? AND ?", trip.started_at, trip.ended_at)
                               .order(created_at: :asc)
                               .to_a

        # Need at least a few telemetry readings to analyze
        if trip_telemetries.size >= 5
          # Look for sequences where speed increases from near 0 to 25+ km/h
          trip_telemetries.each_cons(2) do |t1, t2|
            if t1.speed < 5 && t2.speed >= 25 && (t2.created_at - t1.created_at) <= 10.seconds
              rapid_acceleration_trips += 1
              break # Only count once per trip
            end
          end
        end
      end

      user_achievement = user.user_achievements.find_or_initialize_by(achievement_definition: acceleration_master)
      user_achievement.progress = rapid_acceleration_trips

      if rapid_acceleration_trips >= acceleration_master.threshold && user_achievement.earned_at.nil?
        user_achievement.earned_at = Time.current
        notify_achievement_earned(user, acceleration_master)
      end

      user_achievement.save!
    end

    # Full Send achievement - Reach 50 km/h from standstill in under 10 seconds
    full_send = AchievementDefinition.find_by(name: "Full Send")
    if full_send
      # Count trips with extreme acceleration
      extreme_acceleration_trips = 0

      user.trips.where.not(ended_at: nil).each do |trip|
        # Get all telemetries for this trip
        trip_telemetries = trip.scooter.telemetries
                               .where("created_at BETWEEN ? AND ?", trip.started_at, trip.ended_at)
                               .order(created_at: :asc)
                               .to_a

        # Need at least a few telemetry readings to analyze
        if trip_telemetries.size >= 5
          # Look for sequences where speed increases from near 0 to 50+ km/h
          trip_telemetries.each_cons(2) do |t1, t2|
            if t1.speed < 5 && t2.speed >= 50 && (t2.created_at - t1.created_at) <= 10.seconds
              extreme_acceleration_trips += 1
              break # Only count once per trip
            end
          end
        end
      end

      user_achievement = user.user_achievements.find_or_initialize_by(achievement_definition: full_send)
      user_achievement.progress = extreme_acceleration_trips

      if extreme_acceleration_trips >= full_send.threshold && user_achievement.earned_at.nil?
        user_achievement.earned_at = Time.current
        notify_achievement_earned(user, full_send)
      end

      user_achievement.save!
    end

    # What Stamina achievement - Finish a trip with duration > 90 minutes
    what_stamina = AchievementDefinition.find_by(name: "What Stamina")
    if what_stamina
      # Check if any trip lasts more than 90 minutes
      long_duration_trips = user.trips.where.not(ended_at: nil)
                               .where("(julianday(ended_at) - julianday(started_at)) * 24 * 60 >= ?", 90) # 90 minutes
                               .count

      user_achievement = user.user_achievements.find_or_initialize_by(achievement_definition: what_stamina)
      user_achievement.progress = long_duration_trips

      if long_duration_trips >= what_stamina.threshold && user_achievement.earned_at.nil?
        user_achievement.earned_at = Time.current
        notify_achievement_earned(user, what_stamina)
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

  def self.check_leaderboard_achievements(user)
    # Leaderboard achievements are now handled by LeaderboardAchievementJob
    # This method is kept for backward compatibility
    return
  end

  def self.notify_achievement_earned(user, achievement)
    # Only notify if user has opted in to notifications
    return unless user.user_preference&.receive_achievement_notifications

    # Send email notification
    UserMailer.achievement_earned(user, achievement).deliver_later

    # Could also add in-app notifications, push notifications, etc.
  end

  # Cache methods

  # Cache key for a user's achievements
  def self.cache_key_for(user)
    "user_achievements_#{user.id}_#{user.updated_at.to_i}"
  end

  # Store achievements in cache
  def self.cache_achievements(user, achievements)
    Rails.cache.write(cache_key_for(user), achievements, expires_in: CACHE_EXPIRY)
  end

  # Get cached achievements for a user
  def self.get_cached_achievements(user)
    Rails.cache.read(cache_key_for(user))
  end

  # Invalidate cache for a user
  def self.invalidate_cache(user)
    Rails.cache.delete(cache_key_for(user))
  end
end
