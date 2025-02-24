require "mqtt"

class MqttService
  include Singleton

  attr_reader :response_subscribers, :ack_subscribers

  class << self
    def instance(web_mode: false)
      @instance ||= new(web_mode: web_mode)
    end
  end

  def initialize(web_mode: false)
    Rails.logger.info "MQTT handler initialize (web_mode: #{web_mode.inspect} #{ENV.fetch("MQTT_ROLE", "none").inspect})"
    @web_mode = web_mode
    @subscriptions = Set.new
    @response_subscribers = Concurrent::Map.new if web_mode
    @ack_subscribers = Concurrent::Map.new if web_mode
    setup_client
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
    disconnect
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

    publish(topic, formatted_message.to_json, retain: false, qos: 1)
  rescue => e
    Rails.logger.error "Failed to publish control message: #{e.message}"
    raise
  end

  def publish_command(scooter_vin, command)
    topic = "scooters/#{scooter_vin}/commands"
    message = command.to_json
    publish(topic, message, retain: true, qos: 1)
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

  def setup_client
    @client = MQTT::Client.new(Mqtt::Configuration.client_config(web_mode: @web_mode))
    connect
    subscribe_to_topics
  end

  def connect
    @client&.disconnect rescue nil
    Rails.logger.info "Attempting to connect to MQTT broker at #{@client.host}:#{@client.port} as #{@client.username}"
    @client.connect
    Rails.logger.info "Connected to MQTT broker at #{@client.host}:#{@client.port}"
  rescue => e
    Rails.logger.error "Failed to connect to MQTT: #{e.message}"
    raise e
  end

  def disconnect
    @client&.disconnect
  end

  def publish(topic, message, retain: false, qos: 1)
    @client.publish(topic, message, retain: retain, qos: qos)
    Rails.logger.info "Published message to #{topic}: #{message}"
  end

  def subscribe_to_topics
    Thread.new do
      topics = Mqtt::Configuration.topics(web_mode: @web_mode)
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

    handler = Mqtt::HandlerFactory.create(
      topic: topic,
      message: message,
      web_mode: @web_mode
    )

    handler&.process
  rescue => e
    Rails.logger.error "Error processing MQTT message: #{e.message}\n\n#{e.backtrace.grep(/sunshine/).join("\n")}"
  end
end
