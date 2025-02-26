namespace :achievements do
  desc "Process achievements for a specific user"
  task :process_for_user, [:user_id] => :environment do |t, args|
    user_id = args[:user_id] || 1 # Default to user 1 if no ID provided

    puts "Processing achievements for user #{user_id}..."

    # Find the user
    user = User.find_by(id: user_id)

    if user.nil?
      puts "Error: User with ID #{user_id} not found."
      next
    end

    puts "Found user: #{user.email}"

    # Enqueue the job
    job = AchievementProcessingJob.perform_now(user_id)

    puts "Achievement processing completed for user #{user_id}."
  end
end
