class AddTelemetryReferencesToTrips < ActiveRecord::Migration[8.0]
  def change
    add_reference :trips, :start_telemetry, null: true, foreign_key: { to_table: :telemetries }
    add_reference :trips, :end_telemetry, null: true, foreign_key: { to_table: :telemetries }
  end
end
