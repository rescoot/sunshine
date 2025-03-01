class U2bVinDecoder < VinDecoder
  YEAR_CODES = {
    "H" => 2017, "J" => 2018, "K" => 2019, "L" => 2020,
    "M" => 2021, "N" => 2022, "P" => 2023, "R" => 2024,
    "S" => 2025, "T" => 2026, "V" => 2027, "W" => 2028,
    "X" => 2029, "Y" => 2030, "1" => 2031, "2" => 2032,
    "3" => 2033, "4" => 2034, "5" => 2035, "6" => 2036,
    "7" => 2037, "8" => 2038, "9" => 2039, "A" => 2040
  }

  private

  def model_name
    "Scooter Move"
  end

  def vehicle_type
    "unu-scooter-move"
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
      "4000W motor power (4kW)"
    when "3"
      "3000W motor power (3kW)"
    when "2"
      "2000W motor power (2kW)"
    else
      raise ArgumentError, "Invalid variant code"
    end
  end

  def decode_version
    case @vin[7]
    when "A"
      "Version 25 (max. 25 km/h)"
    when "B"
      "Version 45 (max. 45 km/h)"
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
    if @vin[10] == "Z"
      return "Zhuhai, China"
    end
    raise ArgumentError, "Invalid plant code"
  end
end
