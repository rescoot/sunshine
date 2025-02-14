class U1sVinDecoder < VinDecoder
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
    "Scooter"
  end

  def vehicle_type
    "unu-scooter-1.0"
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
    when "3"
      "3000W motor power (3kW)"
    when "2"
      "2000W motor power (2kW)"
    when "1"
      "1000W motor power (1kW)"
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

  def decode_check_digit
    # Luhn style?
    # 1. Assign numerical values to each character
    weight_factors = [ 8, 7, 6, 5, 4, 3, 2, 10, 0, 9, 8, 7, 6, 5, 4, 3, 2 ]
    table_a1 = Hash[(0..9).to_a.map { |n| [ n.to_s, n ] }]
    table_a2 = Hash[("A".."Z").to_a.zip(1..9)]

    # Combine both tables
    char_values = table_a1.merge(table_a2)

    # 2. Calculate weighted sum
    weighted_sum = @vin.chars.each_with_index.map do |char, index|
      value = char_values.fetch(char, 0)
      value * weight_factors[index]
    end.sum

    # 3. Calculate check digit
    remainder = weighted_sum % 11

    # 4. Determine check digit
    if remainder == 10
      "X"
    else
      remainder.to_s
    end
  end

  def decode_year
    year = YEAR_CODES[@vin[9]]
    raise ArgumentError, "Invalid year code" unless year
    year
  end

  def decode_plant
    return "Zhuhai, China" if @vin[10] == "Z"
    raise ArgumentError, "Invalid plant code"
  end
end
