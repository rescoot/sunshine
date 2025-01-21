class CreateTrips < ActiveRecord::Migration[8.0]
  def change
    create_table :trips do |t|
      t.references :scooter, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.datetime :started_at
      t.decimal :start_lat
      t.decimal :start_lng
      t.datetime :ended_at
      t.decimal :end_lat
      t.decimal :end_lng
      t.decimal :distance
      t.decimal :avg_speed

      t.timestamps
    end
  end
end
