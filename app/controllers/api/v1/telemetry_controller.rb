class Api::V1::TelemetryController < Api::BaseController
  def create
    # TODO: also create as datapoint instead of just updating
    if @current_scooter.update(telemetry_params)
      # data = telemetry_params.to_h
      # data["last_seen_at"] = data["last_seen_at"].iso8601 if data["last_seen_at"]
      # ScooterChannel.broadcast_to(@current_scooter, data)
      head :ok
    else
      render json: { errors: @current_scooter.errors }, status: :unprocessable_entity
    end
  end

  private

  def telemetry_params
    params.require(:telemetry).permit(
      :state, :kickstand, :seatbox, :blinkers,
      :speed, :odometer,
      :battery0_level, :battery1_level,
      :aux_battery_level, :cbb_battery_level,
      :lat, :lng, :last_seen_at
    ).merge(last_seen_at: Time.current)
  end
end
