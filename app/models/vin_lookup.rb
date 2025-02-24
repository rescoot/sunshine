class VinLookup < ApplicationRecord
  validates :vin, presence: true, length: { is: 17 }
  validates :vin, format: { with: /\A(WUN)/, message: "must start with WUN" }

  scope :recent, -> { order(created_at: :desc) }
  scope :most_viewed, -> { order(lookup_count: :desc) }

  def decode
    VinDecoder.for(vin).decode
  rescue => e
    { error: e.message }
  end

  # Increment the lookup count and save the record
  def increment_lookup_count!
    self.lookup_count += 1
    save!
  end

  # Find or create a VIN lookup record and increment the lookup count
  def self.find_or_create_and_increment(vin, attributes = {})
    lookup = find_or_create_by(vin: vin) do |record|
      attributes.each do |key, value|
        record[key] = value
      end
    end

    lookup.increment_lookup_count!
    lookup
  end
end
