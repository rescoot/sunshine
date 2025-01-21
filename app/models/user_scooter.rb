class UserScooter < ApplicationRecord
  belongs_to :user
  belongs_to :scooter

  validates :role, inclusion: { in: %w[owner user] }
  validates :user_id, uniqueness: { scope: :scooter_id }
end
