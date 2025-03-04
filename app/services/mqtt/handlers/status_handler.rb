module Mqtt
  module Handlers
    class StatusHandler < MessageHandler
      def process
        return unless data = parse_json
        return unless scooter = find_scooter(topic_parts[1])

        connected = data["status"] == "connected"

        scooter.with_lock do
          was_offline = !scooter.is_online?

          scooter.update!(
            is_online: connected,
            last_seen_at: connected ? Time.now : scooter.last_seen_at
          )

          scooter.scooter_events.create!(
            event_type: connected ? :connect : :disconnect,
            data: data
          )

          # If scooter just came online, process any queued commands
          if connected && was_offline
            Rails.logger.info "Scooter #{scooter.id} (#{scooter.vin}) connected, processing queued commands"
            ProcessQueuedCommandsJob.perform_later(scooter.id)
          end
        end
      rescue => e
        log_error(e)
      end
    end
  end
end
