class MakeScooterIdNullableInTelemetries < ActiveRecord::Migration[8.0]
  def change
    # Change scooter_id to be nullable
    change_column_null :telemetries, :scooter_id, true
    
    # Update the foreign key to allow null values and set ON DELETE SET NULL
    remove_foreign_key :telemetries, :scooters
    add_foreign_key :telemetries, :scooters, on_delete: :nullify
  end
end
