class ApiToken < ApplicationRecord
  belongs_to :scooter

  attr_accessor :token

  before_create :generate_token

  private

  def generate_token
    self.token = SecureRandom.hex(32)
    self.token_digest = Digest::SHA256.hexdigest(token)
  end
end
