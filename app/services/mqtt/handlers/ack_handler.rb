module Mqtt
  module Handlers
    class AckHandler < MessageHandler
      def initialize(topic:, message:, web_mode: false)
        super(topic: topic, message: message)
        @web_mode = web_mode
      end

      def process
        return unless data = parse_json
        return unless scooter = find_scooter(topic_parts[1])
        return if data.fetch("status", "") == "error"

        if @web_mode
          # Handle subscriptions for web process
          if subscriber = MqttService.instance.ack_subscribers[scooter.vin]
            subscriber.call(data)
          end
        else
          # Background process broadcasts to ActionCable
          ScooterChannel.broadcast_to scooter, {
            type: "ack",
            message: data
          }
        end
      rescue => e
        log_error(e)
      end
    end
  end
end
