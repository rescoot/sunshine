class Admin::UserFeatureFlagsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin!
  before_action :set_user

  def index
    @feature_flags = FeatureFlag.all.order(:name)
    @user_feature_flags = @user.user_feature_flags.includes(:feature_flag)
  end

  def update
    # Process each feature flag
    params[:feature_flags].each do |feature_flag_id, state|
      feature_flag = FeatureFlag.find(feature_flag_id)
      user_feature_flag = @user.user_feature_flags.find_or_initialize_by(feature_flag: feature_flag)

      case state
      when "default"
        # Remove any user-specific setting
        user_feature_flag.destroy if user_feature_flag.persisted?
      when "enabled"
        # Explicitly enable for this user
        user_feature_flag.enabled = true
        user_feature_flag.save
      when "disabled"
        # Explicitly disable for this user
        user_feature_flag.enabled = false
        user_feature_flag.save
      end
    end

    redirect_to admin_user_feature_flags_path(@user), notice: "Feature flags were successfully updated for #{@user.name}."
  end

  private

  def set_user
    @user = User.find(params[:user_id])
  end
end
