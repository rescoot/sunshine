class TripFinalizationJob < ApplicationJob
  queue_as :default

  def perform
    # Check for trips that need to be finalized
    # 1. Trips in potential end state for 15+ minutes
    # 2. Trips with no updates for 1+ hour

    Rails.logger.info "Running TripFinalizationJob at #{Time.current}"

    # Process potential trip ends
    process_potential_trip_ends

    # Process inactivity timeouts
    process_inactivity_timeouts

    Rails.logger.info "Completed TripFinalizationJob at #{Time.current}"
  end

  private

  def process_potential_trip_ends
    Redis.current.scan_each(match: "scooter:*:potential_trip_end") do |key|
      scooter_id = key.split(":")[1]
      telemetry_id = Redis.current.get(key)

      next unless telemetry_id

      telemetry = Telemetry.find_by(id: telemetry_id)
      scooter = Scooter.find_by(id: scooter_id)

      next unless telemetry && scooter

      if telemetry.created_at <= TelemetryTripProcessor::STANDBY_THRESHOLD_MINUTES.minutes.ago
        # This potential end has been in stand-by for 15+ minutes, finalize it
        Rails.logger.info "Finalizing trip for scooter #{scooter.vin} due to standby timeout"
        processor = TelemetryTripProcessor.new(telemetry)
        processor.end_trip(telemetry)
        Redis.current.del(key)
      end
    end
  end

  def process_inactivity_timeouts
    Trip.in_progress.each do |trip|
      scooter = trip.scooter
      last_telemetry = scooter.telemetries
                             .where("created_at > ?", trip.started_at)
                             .order(created_at: :desc)
                             .first

      if last_telemetry && last_telemetry.created_at <= TelemetryTripProcessor::INACTIVITY_TIMEOUT_HOURS.hours.ago
        # No updates for 1+ hour, end the trip
        Rails.logger.info "Finalizing trip ##{trip.id} for scooter #{scooter.vin} due to inactivity timeout"
        processor = TelemetryTripProcessor.new(last_telemetry)
        processor.end_trip(last_telemetry)
      end
    end
  end
end
