class LeaderboardAchievementJob < ApplicationJob
  queue_as :default

  def perform
    # Get all users who have opted in to the leaderboard
    users_with_leaderboard = User.joins(:user_preference)
                                .where(user_preferences: { leaderboard_opt_in: true })

    # Get weekly leaderboard data
    leaderboard_data = LeaderboardService.generate_leaderboard(:week)

    # Process each user who has opted in
    users_with_leaderboard.each do |user|
      # Find user's position
      user_entry = leaderboard_data.find { |entry| entry[:user_id] == user.id }
      next unless user_entry

      # Check Gold achievement
      gold = AchievementDefinition.find_by(name: "Leaderboard Champion - Gold")
      if gold && user_entry[:rank] == 1
        user_achievement = user.user_achievements.find_or_initialize_by(achievement_definition: gold)
        user_achievement.progress = user_entry[:rank] == 1 ? 1 : 0

        if user_entry[:rank] == 1 && user_achievement.earned_at.nil?
          user_achievement.earned_at = Time.current
          AchievementService.notify_achievement_earned(user, gold)
        end

        user_achievement.save!
      end

      # Check Silver achievement
      silver = AchievementDefinition.find_by(name: "Leaderboard Champion - Silver")
      if silver && user_entry[:rank] == 2
        user_achievement = user.user_achievements.find_or_initialize_by(achievement_definition: silver)
        user_achievement.progress = user_entry[:rank] == 2 ? 1 : 0

        if user_entry[:rank] == 2 && user_achievement.earned_at.nil?
          user_achievement.earned_at = Time.current
          AchievementService.notify_achievement_earned(user, silver)
        end

        user_achievement.save!
      end

      # Check Bronze achievement
      bronze = AchievementDefinition.find_by(name: "Leaderboard Champion - Bronze")
      if bronze && user_entry[:rank] == 3
        user_achievement = user.user_achievements.find_or_initialize_by(achievement_definition: bronze)
        user_achievement.progress = user_entry[:rank] == 3 ? 1 : 0

        if user_entry[:rank] == 3 && user_achievement.earned_at.nil?
          user_achievement.earned_at = Time.current
          AchievementService.notify_achievement_earned(user, bronze)
        end

        user_achievement.save!
      end
    end
  end
end
