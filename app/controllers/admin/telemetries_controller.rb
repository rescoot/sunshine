class Admin::TelemetriesController < Admin::ApplicationController
  before_action :set_scooter, only: [ :index, :show ]

  def index
    @telemetries = if @scooter
      @scooter.telemetries
    else
      Telemetry.includes(:scooter)
    end

    # Search filters
    @telemetries = @telemetries.where(state: params[:state]) if params[:state].present?
    @telemetries = @telemetries.where("created_at >= ?", params[:start_date]) if params[:start_date].present?
    @telemetries = @telemetries.where("created_at <= ?", params[:end_date]) if params[:end_date].present?
    @telemetries = @telemetries.where(scooter_id: params[:scooter_id]) if params[:scooter_id].present?
    @telemetries = @telemetries.where("speed >= ?", params[:min_speed]) if params[:min_speed].present?
    @telemetries = @telemetries.where("speed <= ?", params[:max_speed]) if params[:max_speed].present?

    # Get the telemetries for pagination
    @telemetries = @telemetries.order(created_at: :desc).page(params[:page])
  end

  def show
    @telemetry = Telemetry.find(params[:id])
  end

  private

  def set_scooter
    @scooter = Scooter.find(params[:scooter_id]) if params[:scooter_id]
  end
end
