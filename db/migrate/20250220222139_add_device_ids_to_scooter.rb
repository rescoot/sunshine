class AddDeviceIdsToScooter < ActiveRecord::Migration[8.0]
  def change
    add_column :scooters, :device_ids, :json
  end
end
