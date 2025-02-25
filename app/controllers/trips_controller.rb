# app/controllers/trips_controller.rb
class TripsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_trip, only: [ :show ]

  def index
    @trips = current_user.trips.includes(:scooter).order(started_at: :desc)

    # Filter by scooter
    @trips = @trips.where(scooter_id: params[:scooter_id]) if params[:scooter_id].present?

    # Filter by date range
    @trips = @trips.where("started_at >= ?", params[:start_date].to_date.beginning_of_day) if params[:start_date].present?
    @trips = @trips.where("started_at <= ?", params[:end_date].to_date.end_of_day) if params[:end_date].present?

    # Filter by distance
    @trips = @trips.where("distance >= ?", params[:min_distance].to_f * 1000) if params[:min_distance].present?
    @trips = @trips.where("distance <= ?", params[:max_distance].to_f * 1000) if params[:max_distance].present?

    # Filter by duration (in minutes)
    if params[:min_duration].present?
      min_seconds = params[:min_duration].to_i * 60
      @trips = @trips.where("EXTRACT(EPOCH FROM (ended_at - started_at)) >= ?", min_seconds)
    end

    if params[:max_duration].present?
      max_seconds = params[:max_duration].to_i * 60
      @trips = @trips.where("EXTRACT(EPOCH FROM (ended_at - started_at)) <= ?", max_seconds)
    end

    # Filter by average speed
    @trips = @trips.where("avg_speed >= ?", params[:min_speed]) if params[:min_speed].present?
    @trips = @trips.where("avg_speed <= ?", params[:max_speed]) if params[:max_speed].present?

    # Filter by status
    if params[:status].present?
      case params[:status]
      when "in_progress"
        @trips = @trips.where(ended_at: nil)
      when "completed"
        @trips = @trips.where.not(ended_at: nil)
      end
    end

    # Optional: Add pagination
    @trips = @trips.page(params[:page]).per(20) if @trips.respond_to?(:page)
  end

  def show
    # Ensure the trip belongs to the current user and load associated scooter
    @trip = current_user.trips.includes(:scooter).find(params[:id])

    # Calculate additional stats if needed
    @stats = {
      duration: @trip.duration,
      avg_speed: @trip.avg_speed,
      distance_km: @trip.distance ? @trip.distance / 1000.0 : nil
    }
  rescue ActiveRecord::RecordNotFound
    redirect_to trips_path, alert: "Trip not found"
  end

  private

  def set_trip
    @trip = current_user.trips.find(params[:id])
  end
end
