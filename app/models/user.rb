class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable, :confirmable

  has_many :user_scooters
  has_many :scooters, through: :user_scooters
  has_many :trips
  has_many :api_tokens, dependent: :destroy

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
