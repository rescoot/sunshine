module Mqtt
  class HandlerFactory
    class << self
      def create(topic:, message:, web_mode: false)
        topic_parts = topic.split("/")

        case
        when topic == "$CONTROL/dynamic-security/v1/response"
          Handlers::ControlResponseHandler.new(topic: topic, message: message)
        when topic_parts[0] != "scooters"
          handle_unu_message(topic_parts, topic, message)
        else
          create_scooter_handler(topic_parts, topic, message, web_mode)
        end
      end

      private

      def create_scooter_handler(topic_parts, topic, message, web_mode)
        case topic_parts[2]
        when "status"
          Handlers::StatusHandler.new(topic: topic, message: message)
        when "telemetry"
          Handlers::TelemetryHandler.new(topic: topic, message: message)
        when "telemetry_batch"
          Handlers::BatchedTelemetryHandler.new(topic: topic, message: message)
        when "acks"
          Handlers::AckHandler.new(topic: topic, message: message, web_mode: web_mode)
        when "trip"
          Handlers::TripHandler.new(topic: topic, message: message)
        else
          Rails.logger.warn "Unknown message type: #{topic}"
          nil
        end
      end

      def handle_unu_message(topic_parts, topic, message)
        return unless topic_parts[1] == "v1"

        # Store raw message
        RawMessage.create!(
          scooter: Scooter.find_by(imei: topic_parts[0]),
          imei: topic_parts[0],
          topic: topic,
          payload: decode_protobuf(topic, message),
          received_at: Time.current
        )
        nil # No further processing needed
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
    end
  end
end
