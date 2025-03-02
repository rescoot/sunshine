namespace :admin do
  desc "Make a user an admin by email"
  task :make_admin, [ :email ] => :environment do |_task, args|
    if args[:email].blank?
      puts "Error: Email is required"
      puts "Usage: rake admin:make_admin[user@example.com]"
      exit 1
    end

    email = args[:email].strip
    user = User.find_by(email: email)

    if user.nil?
      puts "Error: User with email '#{email}' not found"
      exit 1
    end

    if user.is_admin?
      puts "User '#{email}' is already an admin"
    else
      user.update!(is_admin: true)
      puts "User '#{email}' is now an admin"
    end
  end
end
