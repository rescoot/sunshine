class ScooterChannel < ApplicationCable::Channel
  def subscribed
    logger.info "Scooter #{current_scooter.vin} subscribed to channel"
    stream_for current_scooter
  end

  def unsubscribed
    logger.info "Scooter #{current_scooter.vin} unsubscribed from channel"
  end
end
