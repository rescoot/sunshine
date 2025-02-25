class ScooterCommand < ApplicationRecord
  belongs_to :scooter
  belongs_to :user
end
