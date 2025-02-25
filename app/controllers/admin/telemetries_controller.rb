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
    @telemetries = @telemetries.joins(:scooter).where("LOWER(scooters.name) LIKE ?", "%#{params[:scooter_name].downcase}%") if params[:scooter_name].present?
    @telemetries = @telemetries.where("speed >= ?", params[:min_speed]) if params[:min_speed].present?
    @telemetries = @telemetries.where("speed <= ?", params[:max_speed]) if params[:max_speed].present?

    # Get the telemetries for pagination
    @telemetries = @telemetries.order(created_at: :desc).page(params[:page])

    # Add trip detection information
    if @scooter
      # For a single scooter, we can analyze the telemetries to determine which ones
      # would start or end a trip based on the TripDetectionService

      # Get all telemetries for this scooter in chronological order
      all_telemetries = @scooter.telemetries.order(created_at: :asc).to_a

      # Variables to track state
      last_driving_telemetry = nil
      continuous_non_driving_start = nil

      # Process telemetries to determine which ones would start or end a trip
      all_telemetries.each do |telemetry|
        # Skip telemetries with invalid coordinates
        next unless TripDetectionService.valid_coordinates?(telemetry.lat, telemetry.lng)

        # Check if this telemetry would start a trip
        telemetry.instance_variable_set(:@would_start_trip,
          TripDetectionService.would_start_trip?(telemetry, last_driving_telemetry))

        # Check if this telemetry would end a trip
        telemetry.instance_variable_set(:@would_end_trip,
          TripDetectionService.would_end_trip?(telemetry, continuous_non_driving_start))

        # Update tracking variables
        if TripDetectionService.driving_state?(telemetry.state)
          last_driving_telemetry = telemetry
          continuous_non_driving_start = nil
        elsif continuous_non_driving_start.nil?
          continuous_non_driving_start = telemetry
        end
      end

      # Define methods to access the instance variables
      @telemetries.each do |telemetry|
        telemetry.define_singleton_method(:would_start_trip?) do
          !!instance_variable_get(:@would_start_trip)
        end

        telemetry.define_singleton_method(:would_end_trip?) do
          !!instance_variable_get(:@would_end_trip)
        end
      end
    end
  end

  def show
    @telemetry = Telemetry.find(params[:id])
  end

  private

  def set_scooter
    @scooter = Scooter.find(params[:scooter_id]) if params[:scooter_id]
  end
end
