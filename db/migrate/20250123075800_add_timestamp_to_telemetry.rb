class AddTimestampToTelemetry < ActiveRecord::Migration[8.0]
  def change
    add_column :telemetries, :timestamp, :string
  end
end
