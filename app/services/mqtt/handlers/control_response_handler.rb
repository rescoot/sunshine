module Mqtt
  module Handlers
    class ControlResponseHandler < MessageHandler
      def process
        # Convert message to hash if it's a string
        parsed_message = message.is_a?(String) ? parse_json : message
        return unless parsed_message

        # The README shows responses can be nested
        responses = parsed_message["responses"] || [ parsed_message ]

        responses.each do |response|
          MqttService.instance.response_subscribers&.each do |_, subscriber|
            # Ensure we're passing the entire response object
            subscriber.call(topic, response)
          end
        end
      rescue => e
        log_error(e)
        Rails.logger.error "Problematic message: #{message.inspect}"
      end
    end
  end
end
