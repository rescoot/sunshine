require "mqtt"

class MqttService
  include Singleton

  MQTT_CONFIG = {
    host: ENV.fetch("MQTT_HOST", "localhost"),
    port: ENV.fetch("MQTT_PORT", 8883).to_i,
    username: ENV.fetch("MQTT_USERNAME", "cloud_service"),
    password: ENV.fetch("MQTT_PASSWORD", "password"),
    ssl: ENV.fetch("MQTT_SSL", "true") == "true",
    # cert_file: ENV.fetch("MQTT_SERVER_CRT_PATH"),
    # key_file: ENV.fetch("MQTT_SERVER_KEY_PATH"),
    # ca_file: ENV.fetch("MQTT_CA_CRT_PATH"),
    # verify_peer: true,
    keep_alive: 300,
    clean_session: false,
    client_id: "sunshine-#{Rails.env}-#{Process.pid}"
  }

  class << self
    def instance(web_mode: false)
      @instance ||= new(web_mode: web_mode)
    end
  end

  def initialize(web_mode: false)
    Rails.logger.debug "MQTT handler initialize (web_mode: #{web_mode})"
    @web_mode = web_mode
    @ack_subscribers = Concurrent::Map.new if web_mode
    @client = MQTT::Client.new(MQTT_CONFIG.merge(
      clean_session: web_mode,
      client_id: "sunshine-#{Rails.env}-#{web_mode ? 'web' : 'bg'}-#{Process.pid}-#{SecureRandom.hex(4)}"
    ))
    connect
    subscribe_to_topics if @web_mode # Subscribe immediately in web mode
  end

  def run
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
    Rails.logger.info "Attempting to connect to MQTT broker at #{MQTT_CONFIG[:host]}:#{MQTT_CONFIG[:port]} as #{MQTT_CONFIG[:username]}"
    @client.connect
    Rails.logger.info "Connected to MQTT broker at #{MQTT_CONFIG[:host]}:#{MQTT_CONFIG[:port]}"
  rescue => e
    Rails.logger.error "Failed to connect to MQTT: #{e.message}"
    raise e
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
      @client.subscribe([
        "scooters/+/status",
        "scooters/+/telemetry",
        "scooters/+/acks",
        "scooters/+/data",
        "scooters/+/trip/#",
        "+/v1/#"  # unu cloud messages
      ])

      @client.get do |topic, message|
        process_message(topic, message)
      end
    end
    Rails.logger.debug "subscribed to topics (web_mode: #{@web_mode})"
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

    Rails.logger.debug("Status from #{scooter}: #{data}")
  end

  def process_ack(scooter_vin, message)
    data = JSON.parse(message)
    scooter = Scooter.find_by(vin: scooter_vin)
    return unless scooter

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

    # Update scooter fields
    scooter_attributes = data.reject { |k,v| v.blank? }.slice(
      "state", "kickstand", "seatbox", "blinkers",
      "speed", "odometer",
      "battery0_level", "battery1_level",
      "aux_battery_level", "cbb_battery_level",
      "lat", "lng"
    ).merge(last_seen_at: Time.current)

    scooter.update!(scooter_attributes)
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
