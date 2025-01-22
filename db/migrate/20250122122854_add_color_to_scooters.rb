class AddColorToScooters < ActiveRecord::Migration[8.0]
  def change
    add_column :scooters, :color, :string
  end
end
