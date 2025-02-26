class AddEarnedAtIndexToUserAchievements < ActiveRecord::Migration[8.0]
  def change
    add_index :user_achievements, :earned_at
    add_index :user_achievements, [:user_id, :earned_at]
  end
end
