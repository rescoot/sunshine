class AddOdometerToTrips < ActiveRecord::Migration[8.0]
  def change
    add_column :trips, :start_odometer, :integer
    add_column :trips, :end_odometer, :integer
  end
end
