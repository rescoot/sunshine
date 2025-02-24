class AddMissingIndexes < ActiveRecord::Migration[8.0]
  def change
    # Telemetry indexes for faster queries
    add_index :telemetries, [ :scooter_id, :lat, :lng ], where: "lat IS NOT NULL AND lng IS NOT NULL", name: "index_telemetries_on_scooter_id_and_coordinates"
    add_index :telemetries, [ :scooter_id, :battery0_level, :battery1_level ], name: "index_telemetries_on_scooter_id_and_battery_levels"
    add_index :telemetries, [ :scooter_id, :odometer ], name: "index_telemetries_on_scooter_id_and_odometer"

    # Scooter indexes for frequently queried fields
    add_index :scooters, :last_seen_at
    add_index :scooters, [ :lat, :lng ], where: "lat IS NOT NULL AND lng IS NOT NULL", name: "index_scooters_on_coordinates"
    add_index :scooters, :is_online

    # Trip indexes for statistics
    add_index :trips, [ :scooter_id, :distance ], name: "index_trips_on_scooter_id_and_distance"
    add_index :trips, [ :user_id, :distance ], name: "index_trips_on_user_id_and_distance"
    add_index :trips, [ :started_at, :ended_at ], name: "index_trips_on_started_at_and_ended_at"
  end
end
