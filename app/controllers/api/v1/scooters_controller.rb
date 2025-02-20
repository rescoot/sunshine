class Api::V1::ScootersController < Api::BaseController
  before_action :set_scooter, except: [ :index, :create, :config_for_vin ]

  def index
    @scooters = current_user.scooters
    render json: @scooters
  end

  def show
    render json: @current_scooter, serializer: Api::V1::ScooterSerializer
  end

  def create
    @current_scooter = Scooter.new(scooter_params)

    if @current_scooter.save
      UserScooter.create!(user: current_user, scooter: @current_scooter, role: "owner")
      render json: @current_scooter, status: :created
    else
      render json: { errors: @current_scooter.errors }, status: :unprocessable_entity
    end
  end

  def update
    if @current_scooter.update(scooter_params)
      render json: @current_scooter
    else
      render json: { errors: @current_scooter.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    if @current_scooter.destroy
      head :no_content
    else
      render json: { errors: @current_scooter.errors }, status: :unprocessable_entity
    end
  end

  def generate_token
    @current_scooter.api_token&.destroy
    api_token = ApiToken.generate_for_scooter(@current_scooter)

    render json: {
      token: api_token.token,
      config: @current_scooter.generate_config_with_token(api_token.token)
    }
  end

  def lock
    result = ScooterCommandService.new(@current_scooter).send_command("lock")
    command_response(result)
  end

  def unlock
    result = ScooterCommandService.new(@current_scooter).send_command("unlock")
    command_response(result)
  end

  def blinkers
    state = params[:state].presence_in(Scooter::BLINKER_STATES)
    result = ScooterCommandService.new(@current_scooter).send_command("blinkers", state: state)
    command_response(result)
  end

  def honk
    result = ScooterCommandService.new(@current_scooter).send_command("honk")
    command_response(result)
  end

  def open_seatbox
    result = ScooterCommandService.new(@current_scooter).send_command("open_seatbox")
    command_response(result)
  end

  def ping
    result = ScooterCommandService.new(@current_scooter).send_command("ping")
    command_response(result)
  end

  def update_firmware
    result = ScooterCommandService.new(@current_scooter).send_command("update")
    command_response(result)
  end

  def get_state
    result = ScooterCommandService.new(@current_scooter).send_command("get_state")
    command_response(result)
  end

  def play_sound
    sound = params[:sound].presence_in([ "find_me", "alarm", "chirp" ]) || "chirp"
    result = ScooterCommandService.new(@current_scooter).send_command("play_sound", sound: sound)
    command_response(result)
  end

  def locate
    result = ScooterCommandService.new(@current_scooter).send_command("locate")
    command_response(result)
  end

  def alarm
    duration = params[:duration] || "5s"
    result = ScooterCommandService.new(@current_scooter).send_command("alarm", duration: duration)
    command_response(result)
  end

  def config_for_vin
    @current_scooter = current_user.scooters.find_by!(vin: params[:vin])
    Rails.logger.debug("config for #{@current_scooter.id}")
    @current_scooter.api_token&.destroy
    api_token = ApiToken.generate_for_scooter(@current_scooter)
    config = @current_scooter.generate_config_with_token(api_token.token)
    render plain: config.to_yaml, content_type: "application/x-yaml"
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end

  private

  def set_scooter
    @current_scooter = current_user.scooters.find(params[:id])
  end

  def scooter_params
    params.require(:scooter).permit(:name, :vin, :color, device_ids: {})
  end

  def command_response(result)
    if result.success?
      render json: { status: "success", queued: false }
    else
      render json: { status: "error", message: result.error }, status: :unprocessable_entity
    end
  end
end
