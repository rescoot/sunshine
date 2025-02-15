require "mqtt"

class MqttService
  include Singleton

  MQTT_CONFIG = {
    host: ENV.fetch("MQTT_HOST", "localhost"),
    port: ENV.fetch("MQTT_PORT", 1883).to_i,
    username: ENV.fetch("MQTT_USERNAME", "cloud_service"),
    password: ENV.fetch("MQTT_PASSWORD", "password"),
    ssl: ENV.fetch("MQTT_SSL", "false") == "true",
    # cert_file: ENV.fetch("MQTT_SERVER_CRT_PATH"),
    # key_file: ENV.fetch("MQTT_SERVER_KEY_PATH"),
    # ca_file: ENV.fetch("MQTT_CA_CRT_PATH"),
    # verify_peer: true,
    keep_alive: 300,
    clean_session: false,
    client_id: [ "sunshine", Rails.env, Process.pid, ENV.fetch("MQTT_ROLE", "none") ].join("-")
  }

  class << self
    def instance(web_mode: false)
      @instance ||= new(web_mode: web_mode)
    end
  end

  def initialize(web_mode: false)
    Rails.logger.info "MQTT handler initialize (web_mode: #{web_mode.inspect} #{ENV.fetch("MQTT_ROLE", "none").inspect})"
    Rails.logger.info "=== Call Stack ==="
    caller[0..5].each_with_index do |line, index|
      Rails.logger.info "#{index}: #{line}"
    end
    @web_mode = web_mode
    @subscriptions = Set.new
    @response_subscribers = Concurrent::Map.new if web_mode
    @ack_subscribers = Concurrent::Map.new if web_mode
    @client = MQTT::Client.new(MQTT_CONFIG)
    connect
    subscribe_to_topics
  end

  def run
    Rails.logger.info "Run web_mode=#{@web_mode.inspect}"
    return if @web_mode

    @terminating = false
    subscribe_to_topics

    Signal.trap("TERM") { @terminating = true }
    Signal.trap("INT") { @terminating = true }

    sleep 1 while !@terminating
  ensure
    @client&.disconnect
  end

  def connect
    @client&.disconnect rescue nil
    Rails.logger.info "Attempting to connect to MQTT broker at #{MQTT_CONFIG[:host]}:#{MQTT_CONFIG[:port]} as #{MQTT_CONFIG[:username]}"
    @client.connect
    Rails.logger.info "Connected to MQTT broker at #{MQTT_CONFIG[:host]}:#{MQTT_CONFIG[:port]}"
  rescue => e
    Rails.logger.error "Failed to connect to MQTT: #{e.message}"
    raise e
  end

  def subscribe_to_response(&block)
    subscription_id = SecureRandom.uuid
    @response_subscribers ||= Concurrent::Map.new
    @response_subscribers[subscription_id] = block

    unless @subscriptions.include?("$CONTROL/dynamic-security/v1/response")
      @client.subscribe("$CONTROL/dynamic-security/v1/response", qos: 1)
      @subscriptions.add("$CONTROL/dynamic-security/v1/response")
    end

    subscription_id
  end

  def unsubscribe_from_response(subscription_id)
    @response_subscribers&.delete(subscription_id)
  end

  def publish_control(topic, message)
    # Ensure message is a Hash
    message = JSON.parse(message) if message.is_a?(String)

    # Remove any duplicate or empty keys
    message.reject! { |k, v| k.to_s == "" || v.to_s == "" }

    Rails.logger.debug("publish_control(#{topic.inspect}, #{message.inspect})")

    # Wrap the message in the expected commands structure
    formatted_message = {
      commands: [
        {
          "command" => message[:command].to_s,
          "correlationData" => message[:correlationData] || SecureRandom.uuid,
          # Merge other keys, excluding 'command' and 'correlationData' to avoid duplicates
          **message.except(:command, :correlationData)
        }
      ]
    }

    @client.publish(topic, formatted_message.to_json, retain: false, qos: 1)
    Rails.logger.info "Published control message to #{topic}: #{formatted_message.to_json}"
  rescue => e
    Rails.logger.error "Failed to publish control message: #{e.message}"
    raise
  end

  def handle_control_response(topic, message)
    # Convert message to hash if it's a string
    parsed_message = message.is_a?(String) ? JSON.parse(message) : message

    # The README shows responses can be nested
    responses = parsed_message["responses"] || [ parsed_message ]

    responses.each do |response|
      @response_subscribers&.each do |_, subscriber|
        # Ensure we're passing the entire response object
        subscriber.call(topic, response)
      end
    end
  rescue => e
    Rails.logger.error "Error handling control response: #{e.message}"
    Rails.logger.error "Problematic message: #{message.inspect}"
  end

  def publish_command(scooter_vin, command)
    topic = "scooters/#{scooter_vin}/commands"
    message = command.to_json
    @client.publish(topic, message, retain: true, qos: 1)
    Rails.logger.info "Published command to #{topic}: #{message}"
  rescue => e
    Rails.logger.error "Failed to publish command: #{e.message}"
    raise
  end

  def subscribe_to_acks(scooter_vin, &block)
    Rails.logger.debug("#{scooter_vin} subscribed to acks")
    raise "Not in web mode" unless @web_mode

    @ack_subscribers[scooter_vin] = block
  end

  def unsubscribe_from_acks(scooter_vin)
    raise "Not in web mode" unless @web_mode

    @ack_subscribers.delete(scooter_vin)
  end

  private

  def subscribe_to_topics
    Thread.new do
      topics = if !@web_mode
        # background service handles background updates
        [
          "scooters/+/status",
          "scooters/+/telemetry",
          "scooters/+/trip/#",
          "scooters/+/acks",
          "+/v1/#"  # unu cloud messages
        ]
      else
        # web wants acks, command data and control responses
        [
          "scooters/+/data",
          "scooters/+/acks",
          "$CONTROL/dynamic-security/v1/response"
        ]
      end

      @client.subscribe(topics)
      topics.each { |t| @subscriptions.add(t) }

      @client.get do |topic, message|
        process_message(topic, message)
      end
    end
    Rails.logger.debug "subscribed to topics (web_mode: #{@web_mode})"
  end

  def process_message(topic, message)
    Rails.logger.debug "MQTT: Received message on topic '#{topic}': #{message}"

    if topic == "$CONTROL/dynamic-security/v1/response"
      handle_control_response(topic, message)
      return
    end

    topic_parts = topic.split("/")

    if topic_parts[0] != "scooters"
      process_unu_message(topic_parts[0], topic, message) if topic_parts[1] == "v1"
      return
    end

    scooter_vin = topic_parts[1]
    message_type = topic_parts[2]

    Scooter.find_by(vin: scooter_vin)&.touch(:last_seen_at) if message_type != "status"

    case message_type
    when "status"
      process_status(scooter_vin, message)
    when "telemetry"
      process_telemetry(scooter_vin, message)
    when "acks"
      process_ack(scooter_vin, message)
    when "data"
      process_data(scooter_vin, message)
    when "trip"
      process_trip_update(scooter_vin, topic_parts[3], message)
    end
  rescue => e
    Rails.logger.error "Error processing MQTT message: #{e.message}\n\n#{e.backtrace.grep(/sunshine/).join("\n")}"
  end

  def process_unu_message(imei, topic, message)
    # Store raw message
    RawMessage.create!(
      scooter: Scooter.find_by(imei: imei),
      imei: imei,
      topic: topic,
      payload: decode_protobuf(topic, message),
      received_at: Time.current
    )
  end

  def decode_protobuf(topic, message)
    klass = case topic.split("/").last
    when "scooter_state" then Protos::Unu::V1::ScooterStateBulk
    when "scooter_event" then Protos::Unu::V1::ScooterEventBulk
    when "command_acknowledgement" then Protos::Unu::V1::CommandAcknowledgement
    end

    begin
      decoded = klass.decode(message)
      return decoded.to_h.merge(raw_hex: message.unpack("H*").first)
    rescue Google::Protobuf::ParseError
    end

    { raw_hex: message.unpack("H*").first }
  end

  def process_status(scooter_vin, message)
    data = JSON.parse(message)
    scooter = Scooter.find_by(vin: scooter_vin)
    return unless scooter

    connected = data["status"] == "connected"

    scooter.with_lock do
      scooter.update!(
        is_online: connected,
        last_seen_at: connected ? Time.now : scooter.last_seen_at
      )

      scooter.scooter_events.create!(
        event_type: connected ? :connect : :disconnect,
        data: data
      )
    end
  end

  def process_ack(scooter_vin, message)
    data = JSON.parse(message)
    scooter = Scooter.find_by(vin: scooter_vin)
    return unless scooter
    return if data.fetch("status", "") == "error"

    if @web_mode
      # Handle subscriptions for web process
      if subscriber = @ack_subscribers[scooter_vin]
        subscriber.call(data)
      end
    else
      # Background process broadcasts to ActionCable
      ScooterChannel.broadcast_to scooter, {
        type: "ack",
        message: data
      }
    end
  end

  def process_data(scooter_vin, message)
    data = JSON.parse(message)
    scooter = Scooter.find_by(vin: scooter_vin)
    return unless scooter

    ScooterChannel.broadcast_to scooter, {
      type: case data["type"].to_s
            when "redis" then "redis_result"
            when "shell" then data["done"] ? "shell_complete" : "shell_output"
            end,
      message: data
    }
  end

  def process_telemetry(scooter_vin, message)
    data = JSON.parse(message)
    scooter = Scooter.find_by(vin: scooter_vin)
    return unless scooter

    Rails.logger.debug("Telemetry for #{scooter.vin} (\##{scooter.id}): #{data}")

    # Create telemetry record with full data
    Telemetry.create_from_data!(scooter, data)

    # Update scooter core fields from telemetry
    if data["version"] == 2
      vehicle_state = data.dig("vehicle_state") || {}

      scooter_attributes = {
        state: vehicle_state["state"].presence,
        kickstand: vehicle_state["kickstand"].presence,
        seatbox: vehicle_state["seatbox"].presence,
        blinkers: vehicle_state["blinker_state"].presence,
        speed: data.dig("engine", "speed"),
        odometer: data.dig("engine", "odometer"),
        battery0_level: data.dig("battery0", "level"),
        battery1_level: data.dig("battery1", "level"),
        aux_battery_level: data.dig("aux_battery", "level"),
        cbb_battery_level: data.dig("cbb_battery", "level"),
        lat: data.dig("gps", "lat"),
        lng: data.dig("gps", "lng")
      }.compact
    else
      scooter_attributes = data.reject { |k, v| v.blank? }.slice(
        "state", "kickstand", "seatbox", "blinkers",
        "speed", "odometer",
        "battery0_level", "battery1_level",
        "aux_battery_level", "cbb_battery_level",
        "lat", "lng"
      )
    end

    scooter.update!(scooter_attributes)
    if scooter.state_previously_changed?
      scooter.handle_state_change(scooter.state, scooter.state_previously_was)
    end
  end

  def process_trip_update(scooter_vin, update_type, message)
    data = JSON.parse(message)
    scooter = Scooter.find_by(vin: scooter_vin)
    return unless scooter

    case update_type
    when "start"
      Trip.create!(
        scooter: scooter,
        user: scooter.owner,
        started_at: Time.current,
        start_lat: data["lat"],
        start_lng: data["lng"]
      )
    when "end"
      trip = scooter.trips.in_progress.last
      return unless trip

      trip.update!(
        ended_at: Time.current,
        end_lat: data["lat"],
        end_lng: data["lng"],
        distance: data["distance"],
        avg_speed: data["avg_speed"]
      )
    end
  end
end
