module Mqtt
  module Handlers
    class TripHandler < MessageHandler
      def process
        return unless data = parse_json
        return unless scooter = find_scooter(topic_parts[1])

        case topic_parts[3]
        when "start"
          handle_trip_start(scooter, data)
        when "end"
          handle_trip_end(scooter, data)
        end
      rescue => e
        log_error(e)
      end

      private

      def handle_trip_start(scooter, data)
        Trip.create!(
          scooter: scooter,
          user: scooter.owner,
          started_at: Time.current,
          start_lat: data["lat"],
          start_lng: data["lng"]
        )
      end

      def handle_trip_end(scooter, data)
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
end
