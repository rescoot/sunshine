class CreateTripSegments < ActiveRecord::Migration[8.0]
  def change
    create_table :trip_segments do |t|
      # References
      t.references :trip, null: false, foreign_key: true
      t.references :start_telemetry, null: false, foreign_key: { to_table: :telemetries }
      t.references :end_telemetry, null: false, foreign_key: { to_table: :telemetries }

      # Segment details
      t.float :start_lat
      t.float :start_lng
      t.float :end_lat
      t.float :end_lng
      t.integer :distance # in meters
      t.integer :segment_order # order within the trip
      t.string :segment_type # e.g., 'straight', 'turn', 'loop'

      t.timestamps
    end

    # Add index for faster trip segment lookups
    add_index :trip_segments, [ :trip_id, :segment_order ]
  end
end
