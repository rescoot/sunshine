class AddIsOnlineToScooters < ActiveRecord::Migration[8.0]
  def change
    add_column :scooters, :is_online, :boolean, null: false, default: false
  end
end
