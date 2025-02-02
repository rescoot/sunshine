class RawMessage < ApplicationRecord
  validates :imei, :topic, :payload, :received_at, presence: true

  belongs_to :scooter, foreign_key: :imei, primary_key: :imei, optional: true
end
