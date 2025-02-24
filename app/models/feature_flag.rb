class FeatureFlag < ApplicationRecord
  has_many :user_feature_flags, dependent: :destroy
  has_many :users, through: :user_feature_flags

  validates :key, presence: true, uniqueness: true
  validates :name, presence: true

  # Predefined feature keys
  LEADERBOARDS = "leaderboards"
  ACHIEVEMENTS = "achievements"
  STATISTICS = "statistics"

  # Check if a feature is enabled for a specific user
  def self.enabled_for?(key, user)
    return true if user&.admin?

    feature = find_by(key: key)
    return false unless feature

    # Check if there's a user-specific setting
    if user && (user_flag = UserFeatureFlag.find_by(user: user, feature_flag: feature))
      return user_flag.enabled
    end

    # Fall back to default setting
    feature.default_enabled
  end
end
