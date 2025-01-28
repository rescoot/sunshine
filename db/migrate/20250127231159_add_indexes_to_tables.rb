class AddIndexesToTables < ActiveRecord::Migration[8.0]
  def change
    add_index :trips, [ :user_id, :started_at ]
    add_index :trips, [ :scooter_id, :started_at ]
    add_index :trips, :ended_at
    add_index :user_scooters, [ :user_id, :role ]
  end
end
