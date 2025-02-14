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
