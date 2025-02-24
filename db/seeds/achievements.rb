# Seed achievement definitions
puts "Seeding achievement definitions..."

# Only seed if no achievements exist yet
if AchievementDefinition.count.zero?
  AchievementDefinition.seed_default_achievements
  puts "Created #{AchievementDefinition.count} achievement definitions"
else
  puts "Achievement definitions already exist, skipping"
end
