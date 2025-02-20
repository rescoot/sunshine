class AddBleMacToScooter < ActiveRecord::Migration[8.0]
  def change
    add_column :scooters, :ble_mac, :string
  end
end
