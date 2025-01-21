class Api::V1::TripsController < Api::BaseController
  def start
    trip = current_scooter.trips.build(
      user: current_scooter.owner,
      started_at: Time.current,
      start_lat: params[:lat],
      start_lng: params[:lng]
    )

    if trip.save
      render json: trip, status: :created
    else
      render json: { errors: trip.errors }, status: :unprocessable_entity
    end
  end

  def end
    trip = current_scooter.trips.in_progress.last
    return head :not_found unless trip

    if trip.update(
      ended_at: Time.current,
      end_lat: params[:lat],
      end_lng: params[:lng],
      distance: params[:distance],
      avg_speed: params[:avg_speed]
    )
      render json: trip
    else
      render json: { errors: trip.errors }, status: :unprocessable_entity
    end
  end
end
