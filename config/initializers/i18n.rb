# Set up available locales for the application
Rails.application.config.i18n.available_locales = [ :en, :de_DE, :pirate ]

# Set default locale to English
Rails.application.config.i18n.default_locale = :en

# Load locale files from nested directories
Rails.application.config.i18n.load_path += Dir[Rails.root.join("config", "locales", "**", "*.{rb,yml}")]
