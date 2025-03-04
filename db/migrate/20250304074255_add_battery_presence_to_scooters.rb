class AddBatteryPresenceToScooters < ActiveRecord::Migration[8.0]
  def change
    add_column :scooters, :battery0_present, :boolean
    add_column :scooters, :battery1_present, :boolean
  end
end
