class VinDecoderController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [ :decode ]

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

    # Attempt to decode the VIN
    Rails.logger.debug(VinDecoder.inspect)
    begin
      decoder = VinDecoder.for(vin)
      decode_result = decoder.decode
      Rails.logger.debug decode_result

      # Find or create VIN lookup, ignoring uniqueness errors
      @vin_lookup = VinLookup.find_or_create_by(vin: vin) do |lookup|
        lookup.decode_result = decode_result
        lookup.successful = true
      end
      # always overwrite with latest
      @vin_lookup.decode_result = decode_result
      @vin_lookup.save

      render :result
    rescue => e
      Rails.logger.error(e)
      # Find or create VIN lookup for failed decode
      @vin_lookup = VinLookup.find_or_create_by(vin: vin) do |lookup|
        lookup.decode_result = nil
        lookup.successful = false
        lookup.error_message = e.message
      end

      # Check if VIN format is plausible but not fully decodable
      if vin.start_with?("WUN") && vin.length == 17
        @discord_invite = "https://discord.gg/uxgrUJeM"
        @discord_name = "unu Community"
        flash.now[:community_help] = {
          title: "Need Help Decoding Your VIN?",
          message: "We couldn't fully decode this VIN. Our friendly unu community on Discord might be able to help you figure it out!",
          link: @discord_invite,
          link_text: "Join the #{@discord_name} Discord"
        }
      else
        flash.now[:error] = "Unable to decode VIN: #{e.message}"
      end

      render :index, status: :unprocessable_entity
    end
  end
end
