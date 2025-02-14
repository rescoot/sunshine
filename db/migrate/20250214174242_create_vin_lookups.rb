class CreateVinLookups < ActiveRecord::Migration[8.0]
  def change
    create_table :vin_lookups do |t|
      t.string :vin, null: false
      t.json :decode_result
      t.boolean :successful, default: false
      t.string :error_message

      t.timestamps
    end

    add_index :vin_lookups, :vin, unique: true
    add_index :vin_lookups, :created_at
  end
end
