namespace :achievements do
  desc "Export achievements to YAML files"
  task export_to_yaml: :environment do
    require "yaml"

    # Get all regular achievements
    regular_achievements = AchievementDefinition.where(secret: false).map do |achievement|
      {
        "name" => achievement.name,
        "description" => achievement.description,
        "achievement_type" => achievement.achievement_type,
        "threshold" => achievement.threshold,
        "icon" => achievement.icon,
        "badge_color" => achievement.badge_color,
        "points" => achievement.points,
        "secret" => achievement.secret
      }
    end

    # Get all secret achievements
    secret_achievements = AchievementDefinition.where(secret: true).map do |achievement|
      {
        "name" => achievement.name,
        "description" => achievement.description,
        "achievement_type" => achievement.achievement_type,
        "threshold" => achievement.threshold,
        "icon" => achievement.icon,
        "badge_color" => achievement.badge_color,
        "points" => achievement.points,
        "secret" => achievement.secret
      }
    end

    # Write to YAML files
    File.write(Rails.root.join("config", "achievements", "default.yml"), regular_achievements.to_yaml)
    File.write(Rails.root.join("config", "achievements", "secret.yml.example"), secret_achievements.to_yaml)

    # Also create a copy of the secret achievements as the actual secret.yml file
    # This ensures existing achievements continue to work after the transition
    File.write(Rails.root.join("config", "achievements", "secret.yml"), secret_achievements.to_yaml)

    puts "Exported #{regular_achievements.size} regular achievements to config/achievements/default.yml"
    puts "Exported #{secret_achievements.size} secret achievements to config/achievements/secret.yml.example"
    puts "Also created config/achievements/secret.yml with current secret achievements"
  end
end
