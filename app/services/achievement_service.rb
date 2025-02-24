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

    # Return earned and in-progress achievements
    {
      earned: user.user_achievements.earned.includes(:achievement_definition),
      in_progress: user.user_achievements.in_progress.includes(:achievement_definition)
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
      achievements = AchievementDefinition.by_type(type.to_s)
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

  def self.notify_achievement_earned(user, achievement)
    # Only notify if user has opted in to notifications
    return unless user.user_preference&.receive_achievement_notifications

    # Send email notification
    UserMailer.achievement_earned(user, achievement).deliver_later

    # Could also add in-app notifications, push notifications, etc.
  end
end
