class U2sVinDecoder < VinDecoder
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
    "Scooter Pro"
  end

  def vehicle_type
    if @vin[7] == "A" && %w[H J K L].include?(@vin[9])
      "unu-scooter-2.0"
    else
      "unu-scooter-2.1"
    end
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
      # Zhuhai, China - both Flextronics and Banshing are there
      sn = @vin[11..16].to_i
      if
        (%w[H J K L].include?(@vin[9])) ||     # built before 2021 = Flextronics
        (@vin[9] == "M" && (                  # built in 2021 - could be either
          (@vin[5..6] == "4B" && sn <= 7) ||  # 4kW up to n.7
          (@vin[5..6] == "3B" && sn <= 30)    # 3kW up to n.30
        ))
        return "Zhuhai, China (Flextronics)"
      else
        # everything else was Banshing/A-Motion
        return "Zhuhai, China (Banshing)"
      end
      return "Zhuhai, China (unknown)"
    end
    raise ArgumentError, "Invalid plant code"
  end
end
