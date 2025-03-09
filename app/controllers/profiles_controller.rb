class ProfilesController < ApplicationController
  before_action :authenticate_user!, except: [ :view ]

  def show
    @user = current_user
    @user_preference = @user.user_preference || @user.build_user_preference
    @achievements = AchievementService.get_achievements(@user) if @user.feature_enabled?(FeatureFlag::ACHIEVEMENTS)
    @total_points = AchievementService.total_points(@user) if @user.feature_enabled?(FeatureFlag::ACHIEVEMENTS)
  end

  def edit
    @user_preference = current_user.user_preference || current_user.build_user_preference
  end

  def update
    @user_preference = current_user.user_preference || current_user.build_user_preference

    if @user_preference.update(user_preference_params)
      redirect_to profile_path, notice: "Profile settings updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def view
    @user = User.find(params[:id])
    @user_preference = @user.user_preference

    # Only show profile if user has enabled public profile
    unless @user_preference&.public_profile
      redirect_to leaderboards_path, alert: "This user's profile is not public."
      return
    end

    @achievements = AchievementService.get_achievements(@user) if @user.feature_enabled?(FeatureFlag::ACHIEVEMENTS)
    @total_points = AchievementService.total_points(@user) if @user.feature_enabled?(FeatureFlag::ACHIEVEMENTS)
  end

  private

  def user_preference_params
    params.require(:user_preference).permit(
      :public_profile,
      :leaderboard_opt_in,
      :leaderboard_display_name,
      :receive_achievement_notifications,
      :default_landing_page
    )
  end
end
