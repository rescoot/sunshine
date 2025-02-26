# Seed achievement definitions
puts "Seeding achievement definitions..."

# Force update of achievement definitions
# First, update existing achievements that have specific update logic
AchievementDefinition.seed_default_achievements

# Count how many achievements we have now
achievement_count = AchievementDefinition.count
puts "Achievement definitions updated/created: #{achievement_count} total definitions"
