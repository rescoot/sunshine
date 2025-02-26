namespace :achievements do
  desc "Clean up duplicate achievements"
  task cleanup_duplicates: :environment do
    puts "Starting achievement cleanup..."

    # Find all achievement names that have duplicates
    duplicate_names = AchievementDefinition.group(:name).having("COUNT(*) > 1").pluck(:name)

    if duplicate_names.empty?
      puts "No duplicate achievements found."
      next
    end

    puts "Found #{duplicate_names.size} achievement names with duplicates: #{duplicate_names.join(', ')}"

    # Process each duplicate name
    duplicate_names.each do |name|
      puts "Processing duplicates for: #{name}"

      # Get all achievements with this name, ordered by ID (keeping the oldest one)
      duplicates = AchievementDefinition.where(name: name).order(:id)

      # Keep the first (oldest) record
      original = duplicates.first
      puts "  Keeping original ID: #{original.id} (created: #{original.created_at})"

      # Process the duplicates
      duplicates_to_remove = duplicates.offset(1)
      puts "  Found #{duplicates_to_remove.count} duplicates to process"

      duplicates_to_remove.each do |duplicate|
        puts "  Processing duplicate ID: #{duplicate.id} (created: #{duplicate.created_at})"

        # Find all user achievements linked to this duplicate
        user_achievements = UserAchievement.where(achievement_definition_id: duplicate.id)

        if user_achievements.any?
          puts "    Reassigning #{user_achievements.count} user achievements to original"

          # For each user achievement, either reassign it to the original or delete it if the user already has the original
          user_achievements.each do |ua|
            existing = UserAchievement.find_by(user_id: ua.user_id, achievement_definition_id: original.id)

            if existing
              # User already has the original achievement, so we can delete this one
              puts "      User #{ua.user_id} already has original achievement, deleting duplicate"
              ua.destroy
            else
              # Reassign to the original achievement
              puts "      Reassigning achievement for user #{ua.user_id} to original"
              ua.update(achievement_definition_id: original.id)
            end
          end
        end

        # Now we can safely delete the duplicate achievement definition
        puts "    Deleting duplicate achievement definition"
        duplicate.destroy
      end
    end

    puts "Achievement cleanup completed successfully!"
  end
end
