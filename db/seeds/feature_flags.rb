# Create feature flags
puts "Creating feature flags..."

# Leaderboards feature flag
FeatureFlag.find_or_create_by(key: FeatureFlag::LEADERBOARDS) do |flag|
  flag.name = "Leaderboards"
  flag.description = "Enable access to the leaderboards feature"
  flag.default_enabled = false
end

# Achievements feature flag
FeatureFlag.find_or_create_by(key: FeatureFlag::ACHIEVEMENTS) do |flag|
  flag.name = "Achievements"
  flag.description = "Enable access to the achievements feature"
  flag.default_enabled = false
end

# Statistics feature flag
FeatureFlag.find_or_create_by(key: FeatureFlag::STATISTICS) do |flag|
  flag.name = "Statistics"
  flag.description = "Enable access to the statistics feature"
  flag.default_enabled = false
end

puts "Feature flags created!"
