class AddSecretToAchievementDefinitions < ActiveRecord::Migration[8.0]
  def change
    add_column :achievement_definitions, :secret, :boolean, default: false, null: false
  end
end
