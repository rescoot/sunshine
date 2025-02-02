require "mqtt"

class MqttService
  include Singleton

  MQTT_CONFIG = {
    host: ENV.fetch("MQTT_HOST", "localhost"),
    port: ENV.fetch("MQTT_PORT", 8883).to_i,
    username: ENV.fetch("MQTT_USERNAME", "cloud_service"),
    password: ENV.fetch("MQTT_PASSWORD"),
    ssl: ENV.fetch("MQTT_SSL", "true") == "true",
    # cert_file: ENV.fetch("MQTT_SERVER_CRT_PATH"),
    # key_file: ENV.fetch("MQTT_SERVER_KEY_PATH"),
    # ca_file: ENV.fetch("MQTT_CA_CRT_PATH"),
    # verify_peer: true,
    keep_alive: 300,
    clean_session: false,
    client_id: "sunshine-#{Rails.env}-#{Process.pid}"
  }

  def run
    @terminating = false

    subscribe_to_topics

    Signal.trap("TERM") { @terminating = true }
    Signal.trap("INT") { @terminating = true }

    sleep 1 while !@terminating
  ensure
    @client&.disconnect
  end

  def initialize
    Rails.logger.debug "MQTT handler initialize"
    @client = MQTT::Client.new(MQTT_CONFIG)
    @ack_subscribers = Concurrent::Map.new

    connect
  end

  def connect
    @client.connect
    Rails.logger.info "Connected to MQTT broker at #{MQTT_CONFIG[:host]}:#{MQTT_CONFIG[:port]}"
  rescue => e
    Rails.logger.error "Failed to connect to MQTT: #{e.message}"
  end

  def publish_command(scooter_vin, command)
    topic = "scooters/#{scooter_vin}/commands"
    message = command.to_json
    @client.publish(topic, message, retain: false, qos: 1)
    Rails.logger.info "Published command to #{topic}: #{message}"
  rescue => e
    Rails.logger.error "Failed to publish command: #{e.message}"
    raise
  end

  def subscribe_to_acks(scooter_vin, &block)
    @ack_subscribers[scooter_vin] = block
  end

  def unsubscribe_from_acks(scooter_vin)
    @ack_subscribers.delete(scooter_vin)
  end

  private

  def subscribe_to_topics
    Thread.new do
      @client.subscribe([
        "scooters/+/status",
        "scooters/+/telemetry",
        "scooters/+/acks",
        "scooters/+/trip/#",
        "+/v1/#"  # unu cloud messages: <imei>/v1/[direction]/[type]
      ])

      @client.get do |topic, message|
        process_message(topic, message)
      end
    end
    Rails.logger.debug "subscribed to topics"
  end

  def process_message(topic, message)
    Rails.logger.debug "MQTT: Received message on topic '#{topic}': #{message}"

    topic_parts = topic.split("/")

    if topic_parts[0] != "scooters"
      if topic_parts[1] == "v1"
        # unu cloud message
        process_unu_message(topic_parts[0], topic, message)
      end
      return
    end

    scooter_vin = topic_parts[1]
    message_type = topic_parts[2]

    Rails.logger.debug "MQTT: Processing #{message_type} for scooter #{scooter_vin}"

    case message_type
    when "status"
      process_status(scooteer_vin, message)
    when "telemetry"
      process_telemetry(scooter_vin, message)
    when "acks"
      process_ack(scooter_vin, message)
    when "trip"
      process_trip_update(scooter_vin, topic_parts[3], message)
    end
  rescue => e
    Rails.logger.error "Error processing MQTT message: #{e.message}\n\n#{e.backtrace.grep(/sunshine/).join("\n")}"
  end

  def process_unu_message(imei, topic, message)
    # Store raw message
    RawMessage.create!(
      imei: imei,
      topic: topic,
      payload: decode_protobuf(topic, message),
      received_at: Time.current
    )
  end

  def decode_protobuf(topic, message)
    klass = case topic.split("/").last
    when "scooter_state" then Protos::Unu::V1::ScooterStateBulk
    when "scooter_event" then Protos::Unu::V1::ScooterEvent
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

    Rails.logger.debug("Status from #{scooter}: #{data}")
  end

  def process_ack(scooter_vin, message)
    data = JSON.parse(message)
    if subscriber = @ack_subscribers[scooter_vin]
      subscriber.call(data)
    end
  end

  def process_telemetry(scooter_vin, message)
    data = JSON.parse(message)
    scooter = Scooter.find_by(vin: scooter_vin)
    return unless scooter

    Rails.logger.debug("Telemetry for #{scooter}: #{data}")

    # Create telemetry record with full data
    Telemetry.create_from_data!(scooter, data)

    # Update scooter fields
    scooter_attributes = data.slice(
      "state", "kickstand", "seatbox", "blinkers",
      "speed", "odometer",
      "battery0_level", "battery1_level",
      "aux_battery_level", "cbb_battery_level",
      "lat", "lng"
    ).merge(last_seen_at: Time.current)

    scooter.update!(scooter_attributes)

    # Process any pending commands since the scooter is now online
    process_pending_commands(scooter)
  end

  def process_pending_commands(scooter)
    redis_key = "scooter:#{scooter.vin}:pending_commands"

    while command_json = $redis.with { |conn| conn.lpop(redis_key) }
      command_data = JSON.parse(command_json)
      publish_command(scooter.vin, command_data)
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
