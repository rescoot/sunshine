module Mqtt
  module Handlers
    class StatusHandler < MessageHandler
      def process
        return unless data = parse_json
        return unless scooter = find_scooter(topic_parts[1])

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
      rescue => e
        log_error(e)
      end
    end
  end
end
