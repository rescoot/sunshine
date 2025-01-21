class CreateUserScooters < ActiveRecord::Migration[8.0]
  def change
    create_table :user_scooters do |t|
      t.references :user, null: false, foreign_key: true
      t.references :scooter, null: false, foreign_key: true
      t.string :role, default: 'user'

      t.timestamps
    end

    add_index :user_scooters, [:user_id, :scooter_id], unique: true
  end
end
