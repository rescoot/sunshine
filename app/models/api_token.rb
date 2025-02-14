class ApiToken < ApplicationRecord
  belongs_to :scooter, optional: true
  belongs_to :user, optional: true

  validates :token_digest, presence: true, uniqueness: true
  validates :scope, presence: true, inclusion: { in: %w[user scooter] }
  validates :name, presence: true, if: -> { scope == "user" }

  validate :must_belong_to_user_xor_scooter

  attr_accessor :token

  after_create :store_temporary_token
  after_create :setup_mqtt_auth, if: :scooter_token?
  before_validation :generate_token
  before_destroy :revoke_mqtt_auth, if: :scooter_token?

  scope :user_tokens, -> { where(scope: "user") }
  scope :scooter_tokens, -> { where(scope: "scooter") }

  def self.generate_for_user(user, name:)
    create!(user: user, scope: "user", name: name)
  end

  def self.generate_for_scooter(scooter)
    create!(scooter: scooter, scope: "scooter")
  end

  private

  def generate_token
    self.token = SecureRandom.hex(32)
    self.token_digest = Digest::SHA256.hexdigest(token)
  end

  def store_temporary_token
    $redis.with { |conn| conn.setex("api_token:#{id}", 5.minutes.to_i, token) }
  end

  def self.fetch_token(token_id)
    $redis.with { |conn| conn.get("api_token:#{token_id}") }
  end

  def must_belong_to_user_xor_scooter
    unless user.present? ^ scooter.present?
      errors.add(:base, "Token must belong to either a user or a scooter, not both or neither")
    end
  end

  def setup_mqtt_auth
    MqttAuthService.provision_scooter(scooter, token) if token
  end

  def revoke_mqtt_auth
    MqttAuthService.revoke_scooter(scooter)
  end

  def scooter_token?
    scope == "scooter" && scooter.present?
  end
end
