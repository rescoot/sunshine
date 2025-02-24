class UserPreference < ApplicationRecord
  belongs_to :user

  # Leaderboard participation settings
  attribute :leaderboard_opt_in, :boolean, default: false
  attribute :leaderboard_display_name, :string
  attribute :receive_achievement_notifications, :boolean, default: true
  attribute :notification_settings, :json, default: {}

  validates :leaderboard_display_name, presence: true, if: :leaderboard_opt_in
  validates :leaderboard_display_name, uniqueness: true, allow_blank: true
  validates :leaderboard_display_name, length: { minimum: 3, maximum: 30 }, allow_blank: true

  # Ensure display name doesn't contain offensive content
  validate :display_name_appropriate, if: -> { leaderboard_display_name.present? }

  before_save :set_default_display_name, if: -> { leaderboard_opt_in && leaderboard_display_name.blank? }

  private

  def display_name_appropriate
    # This is a simple placeholder. In a real app, you might use a more sophisticated
    # profanity filter or external service.
    offensive_terms = %w[offensive inappropriate vulgar]

    if offensive_terms.any? { |term| leaderboard_display_name.downcase.include?(term) }
      errors.add(:leaderboard_display_name, "contains inappropriate content")
    end
  end

  def set_default_display_name
    self.leaderboard_display_name = "Rider#{user.id}"
  end
end
