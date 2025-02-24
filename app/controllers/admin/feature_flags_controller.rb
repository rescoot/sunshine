class Admin::FeatureFlagsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin!
  before_action :set_feature_flag, only: [ :show, :edit, :update, :destroy ]

  def index
    @feature_flags = FeatureFlag.all.order(:name)
  end

  def new
    @feature_flag = FeatureFlag.new
  end

  def create
    @feature_flag = FeatureFlag.new(feature_flag_params)

    if @feature_flag.save
      redirect_to admin_feature_flags_path, notice: "Feature flag was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @users_with_config = @feature_flag.user_feature_flags.includes(:user)
  end

  def edit
  end

  def update
    if @feature_flag.update(feature_flag_params)
      redirect_to admin_feature_flags_path, notice: "Feature flag was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @feature_flag.destroy
    redirect_to admin_feature_flags_path, notice: "Feature flag was successfully deleted."
  end

  private

  def set_feature_flag
    @feature_flag = FeatureFlag.find(params[:id])
  end

  def feature_flag_params
    params.require(:feature_flag).permit(:key, :name, :description, :default_enabled)
  end
end
