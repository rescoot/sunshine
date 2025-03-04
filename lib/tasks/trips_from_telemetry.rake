namespace :trips do
  desc "Generate trips from historical telemetry data. Usage: rake trips:generate_from_telemetry[scooter_id] or rake trips:generate_from_telemetry for all scooters"
  task :generate_from_telemetry, [ :scooter_id ] => :environment do |t, args|
    # Parse scooter_id if provided
    scooter_id = args[:scooter_id].to_s.strip

    # Create and run the processor
    processor = HistoricalTripProcessor.new(
      scooter_ids: scooter_id.present? ? [ scooter_id ] : nil
    )

    processor.process
  end
end
