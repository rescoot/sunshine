class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable

  has_many :user_scooters
  has_many :scooters, through: :user_scooters
  has_many :trips

  validates :name, presence: true

  def owner_of?(scooter)
    user_scooters.exists?(scooter: scooter, role: "owner")
  end
end
