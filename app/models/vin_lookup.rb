class VinLookup < ApplicationRecord
  validates :vin, presence: true, length: { is: 17 }
  validates :vin, format: { with: /\A(WUN)/, message: "must start with WUN" }

  scope :recent, -> { order(created_at: :desc) }

  def decode
    VinDecoder.for(vin).decode
  rescue => e
    { error: e.message }
  end
end
