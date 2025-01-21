# app/services/scooter_command_service.rb
class ScooterCommandService
  Result = Struct.new(:success?, :error, :response)
  COMMAND_TIMEOUT = 10.seconds

  def initialize(scooter)
    @scooter = scooter
  end

  def send_command(command, **params)
    request_id = SecureRandom.uuid
    command_data = {
      command: command,
      params: params,
      timestamp: Time.current.to_i,
      request_id: request_id
    }

    # Send command via MQTT
    if publish_mqtt(command_data)
      # Wait for acknowledgment
      response = wait_for_ack(request_id)

      if response
        handle_command_response(command, params, response)
      else
        Result.new(false, "Command timed out", nil)
      end
    else
      Result.new(false, "Failed to send command", nil)
    end
  rescue StandardError => e
    Result.new(false, e.message, nil)
  end

  private

  def publish_mqtt(command_data)
    MqttHandler.instance.publish_command(@scooter.vin, command_data)
  rescue => e
    Rails.logger.error "MQTT publish error: #{e.message}"
    false
  end

  def wait_for_ack(request_id)
    response = nil
    subscription = nil

    begin
      Timeout.timeout(COMMAND_TIMEOUT) do
        subscription = subscribe_to_acks
        while response.nil?
          ack = subscription.pop
          if ack && ack["request_id"] == request_id
            response = ack
            break
          end
        end
      end
    rescue Timeout::Error
      nil
    ensure
      unsubscribe_from_acks(subscription) if subscription
    end

    response
  end

  def subscribe_to_acks
    Queue.new.tap do |queue|
      MqttHandler.instance.subscribe_to_acks(@scooter.vin) do |ack|
        queue.push(ack)
      end
    end
  end

  def unsubscribe_from_acks(subscription)
    MqttHandler.instance.unsubscribe_from_acks(@scooter.vin)
  end

  def handle_command_response(command, params, response)
    success = response["status"] == "success"

    if success
      # Update local state only after confirmation from scooter
      case command
      when "lock"
        @scooter.update(state: "locked")
      when "unlock"
        @scooter.update(state: "unlocked")
      when "blinkers"
        @scooter.update(blinkers: params[:state])
      end

      # Broadcast successful state change to WebSocket
      ActionCable.server.broadcast "scooter_#{@scooter.id}", {
        type: "command_completed",
        command: command,
        params: params,
        scooter: @scooter.as_json
      }
    end

    Result.new(success, response["error"], response)
  end
end
