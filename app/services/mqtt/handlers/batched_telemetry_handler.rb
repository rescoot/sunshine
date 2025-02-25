module Mqtt
  module Handlers
    class BatchedTelemetryHandler < MessageHandler
      def process
        return unless data = parse_json
        return unless scooter = find_scooter(topic_parts[1])

        Rails.logger.debug("Received batched telemetry for #{scooter.vin} (\##{scooter.id}) with #{data['count']} events")

        # Process each telemetry event in the batch
        if data["events"].present? && data["events"].is_a?(Array)
          data["events"].each do |event|
            process_telemetry_event(scooter, event)
          end
        end

        # Update scooter with the latest event data (last event in the batch)
        if data["events"].present? && data["events"].is_a?(Array) && data["events"].last.present?
          update_scooter_attributes(scooter, data["events"].last)
        end
      rescue => e
        log_error(e)
      end

      private

      def process_telemetry_event(scooter, event)
        # Create telemetry record with full data
        Telemetry.create_from_data!(scooter, event)
      rescue => e
        Rails.logger.error("Failed to process telemetry event: #{e.message}")
        Rails.logger.error(e.backtrace.join("\n"))
      end

      def update_scooter_attributes(scooter, data)
        attributes = if data["version"] == 2
          extract_v2_attributes(data)
        else
          extract_v1_attributes(data)
        end

        scooter.update!(attributes)
        if scooter.state_previously_changed?
          scooter.handle_state_change(scooter.state, scooter.state_previously_was)
        end
      end

      def extract_v2_attributes(data)
        vehicle_state = data.dig("vehicle_state") || {}

        {
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
      end

      def extract_v1_attributes(data)
        data.reject { |k, v| v.blank? }.slice(
          "state", "kickstand", "seatbox", "blinkers",
          "speed", "odometer",
          "battery0_level", "battery1_level",
          "aux_battery_level", "cbb_battery_level",
          "lat", "lng"
        )
      end
    end
  end
end
