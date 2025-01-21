# app/controllers/trips_controller.rb
class TripsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_trip, only: [:show]

  def index
    @trips = current_user.trips
                        .includes(:scooter)
                        .order(started_at: :desc)

    # Filter by scooter if requested
    if params[:scooter_id].present?
      @trips = @trips.where(scooter_id: params[:scooter_id])
    end

    # Filter by date range if requested
    if params[:start_date].present?
      start_date = Date.parse(params[:start_date])
      @trips = @trips.where('started_at >= ?', start_date.beginning_of_day)
    end

    if params[:end_date].present?
      end_date = Date.parse(params[:end_date])
      @trips = @trips.where('started_at <= ?', end_date.end_of_day)
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
    redirect_to trips_path, alert: 'Trip not found'
  end

  private

  def set_trip
    @trip = current_user.trips.find(params[:id])
  end
end
