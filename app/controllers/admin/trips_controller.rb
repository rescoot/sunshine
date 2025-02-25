class Admin::TripsController < Admin::ApplicationController
  before_action :set_trip, only: [ :show, :edit, :update, :destroy ]

  def index
    @trips = Trip.includes(:scooter, :user)

    # Filter by user
    @trips = @trips.where(user_id: params[:user_id]) if params[:user_id].present?

    # Filter by scooter
    @trips = @trips.where(scooter_id: params[:scooter_id]) if params[:scooter_id].present?

    # Filter by date range
    @trips = @trips.where("started_at >= ?", params[:start_date]) if params[:start_date].present?
    @trips = @trips.where("started_at <= ?", params[:end_date].to_date.end_of_day) if params[:end_date].present?

    # Filter by distance
    @trips = @trips.where("distance >= ?", params[:min_distance].to_f * 1000) if params[:min_distance].present?
    @trips = @trips.where("distance <= ?", params[:max_distance].to_f * 1000) if params[:max_distance].present?

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

    @trips = @trips.order(created_at: :desc).page(params[:page])
  end

  def show
  end

  def new
    @trip = Trip.new
  end

  def edit
  end

  def create
    @trip = Trip.new(trip_params)

    if @trip.save
      redirect_to admin_trip_path(@trip), notice: "Trip was successfully created."
    else
      render :new
    end
  end

  def update
    if @trip.update(trip_params)
      redirect_to admin_trip_path(@trip), notice: "Trip was successfully updated."
    else
      render :edit
    end
  end

  def destroy
    @trip.destroy
    redirect_to admin_trips_path, notice: "Trip was successfully destroyed."
  end

  private

  def set_trip
    @trip = Trip.find(params[:id])
  end

  def trip_params
    params.require(:trip).permit(
      :user_id, :scooter_id, :started_at, :ended_at,
      :start_lat, :start_lng, :end_lat, :end_lng,
      :start_odometer, :end_odometer, :distance, :avg_speed,
      :start_telemetry_id, :end_telemetry_id,
      :start_gps_distance, :end_gps_distance
    )
  end
end
