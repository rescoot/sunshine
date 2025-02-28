class AddPublicProfileToUserPreferences < ActiveRecord::Migration[7.0]
  def change
    add_column :user_preferences, :public_profile, :boolean, default: false
  end
end
