class AddSpeedToTripSegments < ActiveRecord::Migration[8.0]
  def change
    add_column :trip_segments, :speed, :float
  end
end
