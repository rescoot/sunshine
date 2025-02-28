class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :otp_authenticatable, :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable, :confirmable

  delegate :leaderboard_opt_in, :leaderboard_display_name, :public_profile, to: :user_preference, allow_nil: true
  has_one :user_preference, dependent: :destroy
  has_many :user_achievements, dependent: :destroy
  has_many :achievement_definitions, through: :user_achievements
  has_many :user_scooters
  has_many :scooters, through: :user_scooters
  has_many :trips
  has_many :api_tokens, dependent: :destroy
  has_many :user_feature_flags, dependent: :destroy
  has_many :feature_flags, through: :user_feature_flags

  has_one_attached :avatar do |attachable|
    attachable.variant :thumb, resize_to_limit: [ 150, 150 ]
  end

  validates :name, presence: true
  validate :acceptable_avatar

  attr_accessor :remove_avatar

  def owner_of?(scooter)
    user_scooters.exists?(scooter: scooter, role: "owner")
  end

  def admin?
    is_admin?
  end

  # Check if a feature is enabled for this user
  def feature_enabled?(feature_key)
    FeatureFlag.enabled_for?(feature_key, self)
  end

  # Check and update achievements for this user
  # Returns a hash with earned and in-progress achievements
  def check_achievements
    AchievementService.check_achievements(self)
  end

  # Check if 2FA is mandatory for this user
  def otp_mandatory?
    return false unless is_admin?

    # If the user is an admin, check if they're within the grace period
    if confirmed_at.present? && !otp_enabled?
      grace_period = 24.hours
      return Time.now > (confirmed_at + grace_period)
    end

    # If the user is an admin and outside the grace period, 2FA is mandatory
    is_admin?
  end

  # Get the user's preferred locale
  def preferred_locale
    return locale if locale.present?
    I18n.default_locale
  end

  private

  def acceptable_avatar
    return unless avatar.attached?

    unless avatar.blob.byte_size <= 5.megabytes
      errors.add(:avatar, "is too big")
    end

    acceptable_types = [ "image/jpeg", "image/png", "image/gif" ]
    unless acceptable_types.include?(avatar.content_type)
      errors.add(:avatar, "must be a JPEG, PNG, or GIF")
    end
  end
end
