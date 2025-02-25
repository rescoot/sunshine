class AddLastUnlockUserToScooters < ActiveRecord::Migration[8.0]
  def change
    add_reference :scooters, :last_unlock_user, foreign_key: { to_table: :users }
    add_column :scooters, :last_unlocked_at, :datetime
  end
end
