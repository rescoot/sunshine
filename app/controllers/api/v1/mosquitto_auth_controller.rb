# app/controllers/api/v1/mosquitto_auth_controller.rb
class Api::V1::MosquittoAuthController < Api::BaseController
  skip_before_action :authenticate_token!

  def authenticate
    vin = params[:username]
    token = params[:password]

    scooter = Scooter.find_by(vin: vin)
    token_digest = Digest::SHA256.hexdigest(token)

    if scooter&.api_token&.token_digest == token_digest
      head :ok
    else
      head :unauthorized
    end
  end

  def authorize
    vin = params[:username]
    topic = params[:topic]
    access = params[:acc].to_i # 1 for read, 2 for write

    scooter = Scooter.find_by(vin: vin)
    return head :unauthorized unless scooter

    allowed = case topic
    when "scooters/#{vin}/telemetry"
      access == 2 # Only allow publish
    when "scooters/#{vin}/acks"
      access == 2 # Only allow publish
    when "scooters/#{vin}/commands"
      access == 1 # Only allow subscribe
    else
      false
    end

    allowed ? head(:ok) : head(:forbidden)
  end
end
