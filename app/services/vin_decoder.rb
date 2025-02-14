#!/usr/bin/env ruby

class VinDecoder
  def self.for(vin)
    raise ArgumentError, "VIN must be 17 characters" unless vin.length == 17
    raise ArgumentError, "Invalid VIN format" unless vin.match?(/^WUN/)

    case vin[3..5]
    when "U2S"
      ProVinDecoder.new(vin)
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

class ProVinDecoder < VinDecoder
  YEAR_CODES = {
    'H' => 2017, 'J' => 2018, 'K' => 2019, 'L' => 2020,
    'M' => 2021, 'N' => 2022, 'P' => 2023, 'R' => 2024,
    'S' => 2025, 'T' => 2026, 'V' => 2027, 'W' => 2028,
    'X' => 2029, 'Y' => 2030, '1' => 2031, '2' => 2032,
    '3' => 2033, '4' => 2034, '5' => 2035, '6' => 2036,
    '7' => 2037, '8' => 2038, '9' => 2039, 'A' => 2040
  }

  private

  def model_name
    "Scooter Pro"
  end

  def vehicle_type
    "unu-scooter-2.1"
  end

  def model_specific_fields
    {
      variant: decode_variant,
      version: decode_version,
      check_digit: @vin[8],
      year: decode_year,
      plant: decode_plant
    }
  end

  def decode_variant
    case @vin[6]
    when "4"
      "4000W motor power"
    when "3"
      "3000W motor power"
    when "2"
      "2000W motor power"
    else
      raise ArgumentError, "Invalid variant code"
    end
  end

  def decode_version
    case @vin[7]
    when "A"
      "Version 25 (max 25 km/h)"
    when "B"
      "Version 45 (max 45 km/h)"
    else
      raise ArgumentError, "Invalid version code"
    end
  end

  def decode_year
    year = YEAR_CODES[@vin[9]]
    raise ArgumentError, "Invalid year code" unless year
    year
  end

  def decode_plant
    return "Zhuhai plant - PRC" if @vin[10] == "Z"
    raise ArgumentError, "Invalid plant code"
  end
end

class RebelVinDecoder < VinDecoder
  private

  def model_name
    "Rebel"
  end

  def vehicle_type
    "unu-rebel"
  end

  def model_specific_fields
    {
      unknown_code1: @vin[7],
      unknown_code2: @vin[8],
      unknown_code3: @vin[9],
      unknown_code4: @vin[10]
    }
  end
end

# Command line interface
if __FILE__ == $PROGRAM_NAME
  if ARGV.empty?
    puts "Usage: ruby vin_decoder.rb VIN1 [VIN2 VIN3 ...]"
    puts "Example: ruby vin_decoder.rb WUNU2S3A6KZ000001 WUNURBL22ET000023"
    exit 1
  end

  ARGV.each do |vin|
    begin
      puts "\nDecoding VIN: #{vin}"
      puts "-" * 40
      decoder = BaseVinDecoder.for(vin)
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
