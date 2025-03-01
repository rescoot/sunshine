#!/usr/bin/env ruby

class VinDecoder; end

class VinDecoder
  def self.for(vin)
    raise ArgumentError, "VIN must be 17 characters" unless vin.length == 17
    raise ArgumentError, "Invalid VIN format" unless vin.match?(/^WUN/)

    case vin[3..5]
    when "U2S"
      U2sVinDecoder.new(vin)
    when "U2B"
      U2bVinDecoder.new(vin)
    when "U1S"
      U1sVinDecoder.new(vin)
    when "URB"
      RebelVinDecoder.new(vin) if vin[6] == "L"
    else
      raise ArgumentError, "Unknown vehicle type"
    end
  end

  def initialize(vin)
    @vin = vin
  end

  def decode
    {
      manufacturer: decode_manufacturer,
      model: model_name,
      vehicle_type: vehicle_type,
      serial_number: decode_serial_number
    }.merge(model_specific_fields)
  end

  private

  def decode_manufacturer
    return "unu GmbH" if @vin[0..2] == "WUN"
    raise ArgumentError, "Invalid manufacturer code"
  end

  def decode_serial_number
    serial = @vin[11..16]
    raise ArgumentError, "Invalid serial number" unless serial.match?(/^\d{6}$/)
    serial.to_i
  end

  def model_name
    raise NotImplementedError, "Subclasses must implement model_name"
  end

  def vehicle_type
    raise NotImplementedError, "Subclasses must implement vehicle_type"
  end

  def model_specific_fields
    raise NotImplementedError, "Subclasses must implement model_specific_fields"
  end
end

# Command line interface
if __FILE__ == $PROGRAM_NAME
  require_relative "u1s_vin_decoder"
  require_relative "u2s_vin_decoder"
  require_relative "u2b_vin_decoder"
  require_relative "rebel_vin_decoder"

  if ARGV.empty?
    puts "Usage: ruby vin_decoder.rb VIN1 [VIN2 VIN3 ...]"
    puts "Example: ruby vin_decoder.rb WUNU2S3A6KZ000001 WUNU2B2B5NZ000313 WUNURBL22ET000023"
    exit 1
  end

  ARGV.each do |vin|
    begin
      puts "\nDecoding VIN: #{vin}"
      puts "-" * 40
      decoder = VinDecoder.for(vin)
      result = decoder.decode
      result.each do |key, value|
        next if value.nil?  # Skip nil values
        puts "#{key.to_s.ljust(15)}: #{value}"
      end
    rescue ArgumentError => e
      puts "Error decoding #{vin}: #{e.message}"
    end
  end
end
