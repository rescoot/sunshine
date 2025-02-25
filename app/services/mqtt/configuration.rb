module Mqtt
  class Configuration
    class << self
      def client_config(web_mode: false)
        {
          host: ENV.fetch("MQTT_HOST", "localhost"),
          port: ENV.fetch("MQTT_PORT", 1883).to_i,
          username: ENV.fetch("MQTT_USERNAME", "cloud_service"),
          password: ENV.fetch("MQTT_PASSWORD", "password"),
          ssl: ENV.fetch("MQTT_SSL", "false") == "true",
          keep_alive: 300,
          clean_session: false,
          client_id: generate_client_id(web_mode)
        }
      end

      def topics(web_mode:)
        if web_mode
          # web wants acks, command data and control responses
          [
            "scooters/+/data",
            "scooters/+/acks",
            "$CONTROL/dynamic-security/v1/response"
          ]
        else
          # background service handles background updates
          [
            "scooters/+/status",
            "scooters/+/telemetry",
            "scooters/+/telemetry_batch",
            "scooters/+/trip/#",
            "scooters/+/acks",
            "+/v1/#"  # unu cloud messages
          ]
        end
      end

      private

      def generate_client_id(web_mode)
        [
          "sunshine",
          Rails.env,
          Process.pid,
          web_mode ? "web" : ENV.fetch("MQTT_ROLE", "none")
        ].join("-")
      end
    end
  end
end
