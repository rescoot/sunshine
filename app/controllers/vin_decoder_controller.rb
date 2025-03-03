class VinDecoderController < ApplicationController
  def index
    @vin_lookup = VinLookup.new
  end

  def decode
    # Clean and validate VIN input
    vin = params[:vin]&.upcase&.strip

    # Validate VIN format
    unless vin&.match?(/^WUN[A-Z0-9]{14}$/)
      flash.now[:error] = "Invalid VIN format. Please provide a 17-character VIN starting with WUN."
      return render :index, status: :unprocessable_entity
    end

    existing_lookup = VinLookup.find_by(vin: vin)

    begin
      decoder = VinDecoder.for(vin)
      decode_result = decoder.decode

      if existing_lookup
        existing_lookup.update(
          decode_result: decode_result,
          successful: true,
          error_message: nil
        )

        existing_lookup.increment_lookup_count!

        @vin_lookup = existing_lookup
      else
        @vin_lookup = VinLookup.create(
          vin: vin,
          decode_result: decode_result,
          successful: true,
          lookup_count: 1
        )
      end

      render :result
    rescue => e
      Rails.logger.error("Error decoding VIN #{vin}: #{e.message}")
      Rails.logger.error("Backtrace: #{e.backtrace.join("\n")}")

      if existing_lookup
        existing_lookup.update(
          decode_result: nil,
          successful: false,
          error_message: e.message
        )
        existing_lookup.increment_lookup_count!
        @vin_lookup = existing_lookup
      else
        @vin_lookup = VinLookup.create(
          vin: vin,
          decode_result: nil,
          successful: false,
          error_message: e.message,
          lookup_count: 1
        )
      end

      # Check if VIN format is plausible but not fully decodable
      if vin.start_with?("WUN") && vin.length == 17
        flash.now[:community_help] = {
          title: "Need Help Decoding Your VIN?",
          message: "We couldn't fully decode this VIN. Our friendly unu community on Discord might be able to help you figure it out!",
          link: "https://discord.gg/uxgrUJeM",
          link_text: "Join the unu Community Discord"
        }
      else
        flash.now[:error] = "Unable to decode VIN: #{e.message}"
      end

      render :index, status: :unprocessable_entity
    end
  end
end
