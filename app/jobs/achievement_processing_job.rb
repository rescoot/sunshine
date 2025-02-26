class AchievementProcessingJob < ApplicationJob
  queue_as :background

  # Can be called with a specific user ID or without parameters to process all users
  def perform(user_id = nil)
    if user_id
      # Process achievements for a specific user
      user = User.find_by(id: user_id)
      process_achievements_for_user(user) if user
    else
      # Process achievements for all users
      User.find_each do |user|
        process_achievements_for_user(user)
      end
    end
  end

  private

  def process_achievements_for_user(user)
    # Skip users who don't have the achievements feature enabled
    return unless user.feature_enabled?(FeatureFlag::ACHIEVEMENTS)

    # Process and cache achievements for this user
    achievements = AchievementService.process_and_cache_achievements(user)

    # Log completion
    Rails.logger.info("Processed achievements for user #{user.id}: #{achievements[:earned].size} earned, #{achievements[:in_progress].size} in progress")
  end
end
