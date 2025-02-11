class CreateScooterEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :scooter_events do |t|
      t.references :scooter, null: false, foreign_key: true
      t.integer :event_type, null: false
      t.json :data, null: false, default: {}

      t.timestamps
    end

    add_index :scooter_events, [ :scooter_id, :event_type ]
    add_index :scooter_events, [ :scooter_id, :created_at ]
  end
end
