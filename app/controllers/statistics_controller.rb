class StatisticsController < ApplicationController
  before_action :authenticate_user!
  before_action :check_feature_enabled
  before_action :set_scooter

  def ride_statistics
    @period = params[:period]&.to_sym || :week
    @data = StatisticsService.ride_statistics(@scooter.id, @period)

    respond_to do |format|
      format.html
      format.json { render json: @data }
    end
  end

  def battery_performance
    @period = params[:period]&.to_sym || :week
    @data = StatisticsService.battery_performance(@scooter.id, @period)

    respond_to do |format|
      format.html
      format.json { render json: @data }
    end
  end

  def regeneration_efficiency
    @period = params[:period]&.to_sym || :week
    @data = StatisticsService.regeneration_efficiency(@scooter.id, @period)

    respond_to do |format|
      format.html
      format.json { render json: @data }
    end
  end

  private

  def set_scooter
    @scooter = current_user.scooters.find(params[:scooter_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to scooters_path, alert: "Scooter not found or you don't have access to it."
  end

  def check_feature_enabled
    unless current_user.feature_enabled?(FeatureFlag::STATISTICS)
      redirect_to dashboard_path, alert: "Statistics feature is not available for your account."
    end
  end
end
