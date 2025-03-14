source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.0.1"
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"
# Use sqlite3 as the database for Active Record
gem "sqlite3", ">= 2.1"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Use the database-backed adapters for Rails.cache and Active Job
gem "solid_cache"
gem "solid_queue"

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false
end

gem "actioncable"

gem "devise", "~> 4.9"

gem "jwt", "~> 2.10"

gem "telegram-bot-ruby", "~> 2.2"

gem "active_model_serializers", "~> 0.10.15"

gem "connection_pool", "~> 2.4"

gem "kaminari", "~> 1.2"

gem "ostruct"

gem "redis", "~> 5.3"

gem "mqtt-rails", "~> 1.0"

gem "mqtt", "~> 0.6.0"

gem "importmap-rails", "~> 2.1"

gem "turbo-rails", "~> 2.0"

gem "tailwindcss-rails", "~> 4.1"

gem "stimulus-rails", "~> 1.3"

gem "protobuf", "~> 3.10"

gem "google-protobuf", "~> 3.25"

gem "tailwindcss-ruby", "~> 4.0"

gem "rubocop", "~> 1.74"

# Two-factor authentication for Devise
gem "devise-otp", "~> 1.0.0"
