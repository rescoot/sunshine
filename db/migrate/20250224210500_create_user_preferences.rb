class CreateUserPreferences < ActiveRecord::Migration[8.0]
  def change
    create_table :user_preferences do |t|
      t.references :user, null: false, foreign_key: true
      t.boolean :leaderboard_opt_in, default: false
      t.string :leaderboard_display_name
      t.boolean :receive_achievement_notifications, default: true
      t.json :notification_settings, default: {}

      t.timestamps
    end

    add_index :user_preferences, [ :user_id, :leaderboard_opt_in ]
  end
end
