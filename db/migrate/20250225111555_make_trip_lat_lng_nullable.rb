class MakeTripLatLngNullable < ActiveRecord::Migration[8.0]
  def change
    # Make start lat/lng nullable
    change_column_null :trips, :start_lat, true
    change_column_null :trips, :start_lng, true

    # Make end lat/lng nullable
    change_column_null :trips, :end_lat, true
    change_column_null :trips, :end_lng, true

    # Add columns for tracking distance to first/last valid GPS location
    add_column :trips, :start_gps_distance, :integer, default: 0
    add_column :trips, :end_gps_distance, :integer, default: 0
  end
end
