class Admin::UserAchievementsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin!
  before_action :set_user

  def index
    @achievement_definitions = AchievementDefinition.all.order(:name)
    @user_achievements = @user.user_achievements.includes(:achievement_definition)
  end

  def update
    # Process each achievement
    params[:achievements].each do |achievement_id, state|
      achievement = AchievementDefinition.find(achievement_id)
      user_achievement = @user.user_achievements.find_or_initialize_by(achievement_definition: achievement)

      case state
      when "not_earned"
        # Remove any user achievement
        user_achievement.destroy if user_achievement.persisted?
      when "earned"
        # Mark as earned
        user_achievement.progress = achievement.threshold
        user_achievement.earned_at = Time.current
        user_achievement.save
      when "in_progress"
        # Mark as in progress with partial completion
        progress = params[:progress][achievement_id].to_f
        user_achievement.progress = progress
        user_achievement.earned_at = nil
        user_achievement.save
      end
    end

    redirect_to admin_user_achievements_path(@user), notice: "Achievements were successfully updated for #{@user.name}."
  end

  def create
    achievement = AchievementDefinition.find(params[:achievement_id])
    user_achievement = @user.user_achievements.find_or_initialize_by(achievement_definition: achievement)
    user_achievement.progress = achievement.threshold
    user_achievement.earned_at = Time.current
    user_achievement.save

    redirect_to admin_user_achievements_path(@user), notice: "Achievement '#{achievement.name}' was granted to #{@user.name}."
  end

  def destroy
    user_achievement = @user.user_achievements.find(params[:id])
    user_achievement.destroy

    redirect_to admin_user_achievements_path(@user), notice: "Achievement '#{user_achievement.achievement_definition.name}' was removed from #{@user.name}."
  end

  private

  def set_user
    @user = User.find(params[:user_id])
  end
end
