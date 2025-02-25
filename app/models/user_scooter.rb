class UserScooter < ApplicationRecord
  belongs_to :user
  belongs_to :scooter

  validates :role, inclusion: { in: %w[owner user] }
  validates :user_id, uniqueness: { scope: :scooter_id }

  after_create :check_user_achievements

  private

  def check_user_achievements
    # Check achievements after a user adds a new scooter (especially for ownership achievements)
    user.check_achievements if user && role == "owner"
  end
end
