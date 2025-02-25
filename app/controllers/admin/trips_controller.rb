class Admin::TripsController < Admin::ApplicationController
  before_action :set_trip, only: [ :show, :edit, :update, :destroy ]

  def index
    @trips = Trip.includes(:scooter, :user)
                .order(created_at: :desc)
                .page(params[:page])
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
