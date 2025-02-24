class AchievementDefinition < ApplicationRecord
  has_many :user_achievements, dependent: :destroy
  has_many :users, through: :user_achievements

  # Achievement types
  TYPES = {
    distance: "Total distance traveled (km)",
    duration: "Total riding time (hours)",
    trips: "Number of trips completed",
    speed: "Maximum speed achieved (km/h)",
    ownership: "Number of scooters owned",
    special: "Special achievements"
  }.freeze

  BADGE_COLORS = %w[indigo green purple orange red yellow pink blue].freeze

  validates :name, presence: true
  validates :description, presence: true
  validates :achievement_type, presence: true, inclusion: { in: TYPES.keys.map(&:to_s) }
  validates :threshold, presence: true, numericality: { greater_than: 0 }
  validates :icon, presence: true
  validates :badge_color, inclusion: { in: BADGE_COLORS }

  # Scopes
  scope :by_type, ->(type) { where(achievement_type: type) }
  scope :ordered_by_threshold, -> { order(threshold: :asc) }
  scope :visible, -> { where(secret: false) }
  scope :secret, -> { where(secret: true) }

  def self.seed_default_achievements
    # Always seed achievements, even if some already exist
    seed_from_yaml
  end

  def self.seed_from_yaml
    require "yaml"

    default_path = Rails.root.join("config", "achievements", "default.yml")
    if File.exist?(default_path)
      regular_achievements = YAML.load_file(default_path)
      regular_achievements.each do |attrs|
        find_or_create_achievement(attrs["name"], attrs)
      end
    end

    # Load secret achievements from secret.yml if it exists
    secret_path = Rails.root.join("config", "achievements", "secret.yml")
    if File.exist?(secret_path)
      secret_achievements = YAML.load_file(secret_path)
      secret_achievements.each do |attrs|
        find_or_create_achievement(attrs["name"], attrs)
      end
    end
  end

  def self.find_or_create_achievement(name, attributes)
    # Convert string keys to symbols for compatibility with existing code
    symbolized_attrs = {}
    attributes.each do |k, v|
      symbolized_attrs[k.to_sym] = v
    end

    achievement = find_by(name: name)
    if achievement
      achievement.update!(symbolized_attrs)
    else
      create!(symbolized_attrs.merge(name: name))
    end
    achievement || find_by(name: name)
  end

  def progress_percentage(progress)
    return 100 if progress >= threshold
    ((progress / threshold) * 100).round
  end

  def badge_class
    "bg-#{badge_color}-100 text-#{badge_color}-800"
  end
end
