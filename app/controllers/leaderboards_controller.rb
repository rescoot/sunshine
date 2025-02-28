class LeaderboardsController < ApplicationController
  before_action :authenticate_user!, except: [ :index ]
  before_action :check_feature_enabled, except: [ :index ]
  before_action :set_period

  def index
    @leaderboard = LeaderboardService.generate_leaderboard(@period)

    # Get community averages for all users
    @community_averages = LeaderboardService.community_averages(@period)

    if user_signed_in? && current_user.feature_enabled?(FeatureFlag::LEADERBOARDS)
      # Find current user's position
      @user_position = LeaderboardService.user_position(current_user.id, @period)
      @user_comparison = LeaderboardService.user_comparison(current_user.id, @period)
    end

    respond_to do |format|
      format.html
      format.json { render json: { leaderboard: @leaderboard, user_position: @user_position } }
    end
  end

  def settings
    @user_preference = current_user.user_preference || current_user.build_user_preference
  end

  def update_settings
    @user_preference = current_user.user_preference || current_user.build_user_preference

    if @user_preference.update(user_preference_params)
      redirect_to leaderboards_path, notice: "Leaderboard settings updated successfully."
    else
      render :settings, status: :unprocessable_entity
    end
  end

  private

  def user_preference_params
    params.require(:user_preference).permit(:leaderboard_opt_in, :leaderboard_display_name, :receive_achievement_notifications)
  end

  def set_period
    @period = params[:period]&.to_sym || :week
  end

  def check_feature_enabled
    unless current_user.feature_enabled?(FeatureFlag::LEADERBOARDS)
      redirect_to dashboard_path, alert: "Leaderboards feature is not available for your account."
    end
  end
end
