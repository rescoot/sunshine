class ScooterCommandService
  Result = Struct.new(:success?, :error, :response)
  COMMAND_TIMEOUT = 10.seconds # Increased from 5 to 10 seconds
  VALID_REDIS_COMMANDS = %w[get set hget hset hgetall lpush lpop].freeze

  def initialize(scooter, user = nil)
    @scooter = scooter
    @user = user
  end

  def send_command(command, **params)
    request_id = SecureRandom.uuid
    command_data = {
      command: command,
      params: params,
      timestamp: Time.current.to_i,
      request_id: request_id
    }

    command_data[:stream] = true if command == "shell"

    # Validate redis commands
    if command == "redis"
      return Result.new(false, "Invalid Redis command") unless valid_redis_command?(params[:cmd])
    end

    # Record the command in the database if a user is provided
    scooter_command = nil
    if @user
      scooter_command = ScooterCommand.create!(
        scooter: @scooter,
        user: @user,
        command: command,
        params: params,
        request_id: request_id
      )

      # If this is an unlock command, also update the scooter's last_unlock_user
      if command == "unlock"
        @scooter.update(
          last_unlock_user: @user,
          last_unlocked_at: Time.current
        )
      end
    end

    # Check if scooter is online
    if @scooter.is_online?
      # Scooter is online, send command immediately
      Rails.logger.debug("Publishing #{command_data}")
      if publish_mqtt(command_data)
        Rails.logger.debug("Waiting for ack for #{request_id}")
        response = wait_for_ack(request_id)
        if response
          Rails.logger.debug("Got ack!")
          scooter_command&.mark_as_succeeded if response["status"] == "success"
          scooter_command&.mark_as_failed if response["status"] == "error"
          handle_command_response(command_data[:command], command_data[:params], response)
        else
          scooter_command&.mark_as_failed
          Result.new(false, "Command timed out")
        end
      else
        scooter_command&.mark_as_failed
        Result.new(false, "Failed to send command")
      end
    elsif scooter_command&.queueable?
      # Scooter is offline but command is queueable, queue it
      scooter_command.update(queued: true)
      Result.new(true, nil, { queued: true })
    else
      # Scooter is offline and command is not queueable
      Result.new(false, "Scooter is offline and command cannot be queued")
    end
  rescue StandardError => e
    Rails.logger.error("Error sending command: #{e.message}")
    Result.new(false, e.message)
  end

  # Method to send a previously queued command
  def send_queued_command(command)
    return Result.new(false, "Command has expired") if command.expired?

    command_data = {
      command: command.command,
      params: command.params,
      timestamp: Time.current.to_i,
      request_id: command.request_id
    }

    command_data[:stream] = true if command.command == "shell"

    Rails.logger.debug("Publishing queued command #{command_data}")
    if publish_mqtt(command_data)
      Rails.logger.debug("Waiting for ack for #{command.request_id}")
      response = wait_for_ack(command.request_id)
      if response
        Rails.logger.debug("Got ack!")
        command.mark_as_succeeded if response["status"] == "success"
        command.mark_as_failed if response["status"] == "error"
        handle_command_response(command.command, command.params, response)
      else
        command.mark_as_failed
        Result.new(false, "Command timed out")
      end
    else
      command.mark_as_failed
      Result.new(false, "Failed to send command")
    end
  rescue StandardError => e
    Rails.logger.error("Error sending queued command: #{e.message}")
    Result.new(false, e.message)
  end

  private

  def valid_redis_command?(cmd)
    VALID_REDIS_COMMANDS.include?(cmd.to_s.downcase)
  end

  def publish_mqtt(command_data)
    MqttService.instance.publish_command(@scooter.vin, command_data)
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
      MqttService.instance.subscribe_to_acks(@scooter.vin) do |ack|
        queue.push(ack)
      end
    end
  end

  def unsubscribe_from_acks(subscription)
    MqttService.instance.unsubscribe_from_acks(@scooter.vin)
  end

  def handle_command_response(command, params, response)
    success = response["status"] == "success"

    if success
      case command
      when "redis", "shell"
        handle_data_response(command, response)
      else
        handle_existing_command(command, params, response)
      end
    end

    Result.new(success, response["error"], response)
  end

  def handle_data_response(command, response)
    case command
    when "shell"
      if response["stream"]
        stream_shell_output(response)
      else
        handle_shell_completion(response)
      end
    when "redis"
      handle_redis_result(response)
    end
  end

  def stream_shell_output(response)
    ActionCable.server.broadcast "scooter_#{@scooter.id}", {
      type: "shell_output",
      output: response["output"],
      output_type: response["output_type"],
      done: response["done"]
    }
  end

  def handle_shell_completion(response)
    ActionCable.server.broadcast "scooter_#{@scooter.id}", {
      type: "shell_complete",
      stdout: response["stdout"],
      stderr: response["stderr"],
      exit_code: response["exit_code"]
    }
  end

  def handle_redis_result(response)
    ActionCable.server.broadcast "scooter_#{@scooter.id}", {
      type: "redis_result",
      command: response["command"],
      result: response["result"]
    }
  end

  def handle_existing_command(command, params, response)
    ActionCable.server.broadcast "scooter_#{@scooter.id}", {
      type: "command_completed",
      command: command,
      params: params,
      scooter: @scooter.as_json
    }

    # Broadcast updates to the quick controls section
    Turbo::StreamsChannel.broadcast_replace_to(
      @scooter,
      target: "scooter_#{@scooter.id}_quick_controls",
      partial: "scooters/quick_controls",
      locals: { scooter: @scooter }
    )
  end
end
