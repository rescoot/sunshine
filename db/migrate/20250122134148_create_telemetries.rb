class CreateTelemetries < ActiveRecord::Migration[8.0]
  def change
    create_table :telemetries do |t|
      t.references :scooter, null: false, foreign_key: true

      # Basic state
      t.string :state
      t.string :kickstand
      t.string :seatbox
      t.string :blinkers

      # Movement data
      t.decimal :speed, precision: 10, scale: 2
      t.decimal :odometer, precision: 10, scale: 2

      # Motor data
      t.decimal :motor_voltage, precision: 10, scale: 2
      t.decimal :motor_current, precision: 10, scale: 2
      t.decimal :temperature, precision: 10, scale: 2

      # Battery data
      t.decimal :battery0_level, precision: 5, scale: 2
      t.decimal :battery1_level, precision: 5, scale: 2
      t.boolean :battery0_present
      t.boolean :battery1_present
      t.decimal :aux_battery_level, precision: 5, scale: 2
      t.decimal :aux_battery_voltage, precision: 10, scale: 2
      t.decimal :cbb_battery_level, precision: 5, scale: 2
      t.decimal :cbb_battery_current, precision: 10, scale: 2

      # Location
      t.decimal :lat, precision: 10, scale: 6
      t.decimal :lng, precision: 10, scale: 6

      t.timestamps
    end

    add_index :telemetries, [ :scooter_id, :created_at ]
  end
end
