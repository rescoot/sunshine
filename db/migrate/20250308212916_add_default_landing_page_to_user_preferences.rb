class AddDefaultLandingPageToUserPreferences < ActiveRecord::Migration[8.0]
  def change
    add_column :user_preferences, :default_landing_page, :string, default: 'dashboard'
  end
end
