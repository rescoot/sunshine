class AddImeiToScooters < ActiveRecord::Migration[8.0]
  def change
    add_column :scooters, :imei, :string
    add_index :scooters, :imei, unique: true
  end
end
