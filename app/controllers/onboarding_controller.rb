class OnboardingController < ApplicationController
  before_action :authenticate_user!
  before_action :redirect_if_completed, only: [ :index, :create_scooter ]

  def index
    @scooter = Scooter.new
  end

  def create_scooter
    @scooter = Scooter.new(scooter_params.merge(default_states))

    if @scooter.save
      UserScooter.create!(user: current_user, scooter: @scooter, role: "owner")
      @api_token = ApiToken.create!(scooter: @scooter)

      redirect_to config_onboarding_path(scooter_id: @scooter.id, token_id: @api_token.id)
    else
      render :index, status: :unprocessable_entity
    end
  end

  def config
    @scooter = current_user.scooters.find(params[:scooter_id])
    token = ApiToken.fetch_token(params[:token_id])

    unless token
      flash[:error] = "Token expired. Please generate a new one."
      redirect_to scooter_path(@scooter) and return
    end

    @config = {
      "vin" => @scooter.vin,
      "telemetry" => {
        "check_interval" => "100ms",
        "min_interval" => "1s",
        "max_interval" => "300s"
      },
      "mqtt" => {
        "broker_url" => "tcp://mqtt.sunshine.rescoot.org:1883",
        "token" => token
      }
    }
  end

  private

  def scooter_params
    params.require(:scooter).permit(:name, :vin, :color)
  end

  def default_states
    {
      state: "stand-by",
      kickstand: "down",
      seatbox: "closed",
      blinkers: "off",
      speed: 0,
      odometer: 0,
      battery0_level: 0,
      battery1_level: 0,
      aux_battery_level: 0,
      cbb_battery_level: 0
    }
  end

  def redirect_if_completed
    redirect_to dashboard_path if current_user.scooters.exists?
  end
end
