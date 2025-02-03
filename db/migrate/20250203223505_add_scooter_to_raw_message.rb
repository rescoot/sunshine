class AddScooterToRawMessage < ActiveRecord::Migration[8.0]
  def change
    add_reference :raw_messages, :scooter, null: true, foreign_key: true
  end
end
