class CreateScooters < ActiveRecord::Migration[8.0]
  def change
    create_table :scooters do |t|
      t.string :name
      t.string :vin

      t.string :state
      t.string :kickstand
      t.string :seatbox
      t.string :blinkers
      t.decimal :speed

      t.decimal :odometer

      t.decimal :battery0_level
      t.decimal :battery1_level
      t.decimal :aux_battery_level
      t.decimal :cbb_battery_level

      t.decimal :lat
      t.decimal :lng

      t.datetime :last_seen_at

      t.timestamps
    end

    add_index :scooters, :vin, unique: true
  end
end
