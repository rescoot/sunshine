class Api::V1::ScootersController < Api::BaseController
  before_action :set_scooter, except: [ :index, :create ]

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

  private

  def set_scooter
    @current_scooter = current_user.scooters.find(params[:id])
  end

  def scooter_params
    params.require(:scooter).permit(:name, :vin, :color)
  end

  def command_response(result)
    if result.success?
      render json: { status: "success", queued: result.enqueued }
    else
      render json: { status: "error", message: result.error }, status: :unprocessable_entity
    end
  end
end
