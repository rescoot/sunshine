module Mqtt
  class MessageHandler
    def initialize(topic:, message:)
      @topic = topic
      @message = message
      @topic_parts = topic.split("/")
    end

    def process
      raise NotImplementedError, "#{self.class} must implement #process"
    end

    protected

    attr_reader :topic, :message, :topic_parts

    def parse_json
      JSON.parse(message)
    rescue JSON::ParserError => e
      Rails.logger.error "Failed to parse JSON message: #{e.message}"
      nil
    end

    def find_scooter(identifier)
      Scooter.find_by(vin: identifier)
    end

    def log_error(error)
      Rails.logger.error "Error processing MQTT message: #{error.message}\n\n#{error.backtrace.grep(/sunshine/).join("\n")}"
    end
  end
end
