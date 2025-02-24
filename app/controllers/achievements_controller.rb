class AchievementsController < ApplicationController
  before_action :authenticate_user!
  before_action :check_feature_enabled

  def index
    # Check for new achievements
    @achievements = AchievementService.check_achievements(current_user)

    # Get total points
    @total_points = AchievementService.total_points(current_user)

    # Group achievements by type for the view
    @achievement_types = AchievementDefinition::TYPES

    # Group earned achievements by type
    @earned_by_type = @achievements[:earned].group_by { |ua| ua.achievement_definition.achievement_type }

    # Group in-progress achievements by type
    @in_progress_by_type = @achievements[:in_progress].group_by { |ua| ua.achievement_definition.achievement_type }

    # Get next achievements to earn
    @next_achievements = AchievementService.next_achievements(current_user)

    respond_to do |format|
      format.html
      format.json { render json: { achievements: @achievements, total_points: @total_points } }
    end
  end

  private

  def check_feature_enabled
    unless current_user.feature_enabled?(FeatureFlag::ACHIEVEMENTS)
      redirect_to dashboard_path, alert: "Achievements feature is not available for your account."
    end
  end
end
