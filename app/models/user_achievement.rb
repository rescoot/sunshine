class UserAchievement < ApplicationRecord
  belongs_to :user
  belongs_to :achievement_definition

  validates :user_id, uniqueness: { scope: :achievement_definition_id }

  scope :earned, -> { where.not(earned_at: nil) }
  scope :in_progress, -> { where(earned_at: nil) }
  scope :recent, -> { order(earned_at: :desc) }

  def earned?
    earned_at.present?
  end

  def progress_percentage
    return 100 if earned?
    achievement_definition.progress_percentage(progress)
  end

  def formatted_progress
    case achievement_definition.achievement_type
    when "distance"
      "#{progress.round(1)} / #{achievement_definition.threshold} km"
    when "duration"
      "#{progress.round(1)} / #{achievement_definition.threshold} hours"
    when "trips"
      "#{progress.to_i} / #{achievement_definition.threshold.to_i} trips"
    when "speed"
      "#{progress.round(1)} / #{achievement_definition.threshold} km/h"
    when "ownership"
      "#{progress.to_i} / #{achievement_definition.threshold.to_i} scooters"
    else
      "#{progress} / #{achievement_definition.threshold}"
    end
  end
end
