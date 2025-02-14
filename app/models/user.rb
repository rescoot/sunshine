class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable

  has_one_attached :avatar

  has_many :user_scooters
  has_many :scooters, through: :user_scooters
  has_many :trips
  has_many :api_tokens, dependent: :destroy

  validates :name, presence: true

  def owner_of?(scooter)
    user_scooters.exists?(scooter: scooter, role: "owner")
  end

  def admin?
    id == 1
  end
end
