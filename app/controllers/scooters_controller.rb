class ScootersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_scooter, except: [ :index, :new, :create ]
  before_action :ensure_owner!, only: [ :edit, :update, :destroy ]
  before_action :ensure_admin!, only: [ :redis_command, :shell_command ]

  def index
    @scooters = current_user.scooters
  end

  def show
    @trips = @scooter.trips.order(started_at: :desc).limit(10)
    @waiting_for_telemetry = @scooter.telemetries.none?
    @show_token_section = @waiting_for_telemetry || flash[:token].present? || params[:token_id].present?

    if flash[:token].present?
      $redis.with do |conn|
        conn.setex("scooter_token:#{@scooter.id}", 5.minutes.to_i, flash[:token])
      end
      @token = flash[:token]
    elsif params[:token_id].present?
      @token = ApiToken.fetch_token(params[:token_id])
    end

    respond_to do |format|
      format.html
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.update("scooter_#{@scooter.id}_status",
                             partial: "scooters/status",
                             locals: { scooter: @scooter }),
          turbo_stream.update("scooter_#{@scooter.id}_controls",
                             partial: "scooters/controls",
                             locals: { scooter: @scooter })
        ]
      end
    end
  end

  def new
    @scooter = Scooter.new
  end

  def create
    @scooter = Scooter.new(scooter_params)

    if @scooter.save
      UserScooter.create!(user: current_user, scooter: @scooter, role: "owner")
      redirect_to @scooter, notice: "Scooter was successfully registered."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @scooter.update(scooter_params)
      redirect_to @scooter, notice: "Scooter was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @scooter.destroy
    redirect_to scooters_path, notice: "Scooter was successfully deleted.", status: :see_other
  end

  def show_token_management
    respond_to do |format|
      format.html { redirect_to @scooter }
      format.turbo_stream {
        render turbo_stream: turbo_stream.update("api_token_section",
          partial: "api_token",
          locals: { scooter: @scooter, token: nil })
      }
    end
  end

  # Remote control actions
  def lock
    result = ScooterCommandService.new(@scooter).send_command("lock")
    handle_command_result(result, "Lock command")
  end

  def unlock
    result = ScooterCommandService.new(@scooter, current_user).send_command("unlock")
    handle_command_result(result, "Unlock command")
  end

  def blinkers
    state = params[:state].presence_in(Scooter::BLINKER_STATES) || "off"
    result = ScooterCommandService.new(@scooter).send_command("blinkers", state: state)
    handle_command_result(result, "Blinkers command")
  end

  def honk
    result = ScooterCommandService.new(@scooter).send_command("honk")
    handle_command_result(result, "Honk command")
  end

  def open_seatbox
    result = ScooterCommandService.new(@scooter).send_command("open_seatbox")
    handle_command_result(result, "Open seatbox")
  end

  def ping
    result = ScooterCommandService.new(@scooter).send_command("ping")
    handle_command_result(result, "Ping")
  end

  def update_firmware
    result = ScooterCommandService.new(@scooter).send_command("update")
    handle_command_result(result, "Firmware update")
  end

  def get_state
    result = ScooterCommandService.new(@scooter).send_command("get_state")
    handle_command_result(result, "State update")
  end

  def play_sound
    sound = params[:sound].presence_in([ "find_me", "alarm", "chirp" ]) || "chirp"
    result = ScooterCommandService.new(@scooter).send_command("play_sound", sound: sound)
    handle_command_result(result, "Sound command")
  end

  def locate
    handle_command_result(ScooterCommandService.new(@scooter).send_command("locate"), "Location request")
  end

  def alarm
    duration = params[:duration] || "5s"  # default to 5 seconds if not specified
    handle_command_result(ScooterCommandService.new(@scooter).send_command("alarm", duration: duration), "Alarm trigger")
  end

  def redis_command
    cmd = params[:cmd]
    args = Array(params[:args])
    result = ScooterCommandService.new(@scooter).send_command("redis", cmd: cmd, args: args)
    handle_command_result(result, "Redis command")
  end

  def shell_command
    cmd = params[:cmd]
    result = ScooterCommandService.new(@scooter).send_command("shell", cmd: cmd)
    handle_command_result(result, "Shell command")
  end

  def regenerating?
    @scooter.telemetry&.motor_current < 0.0 rescue false
  end

  private

  def set_scooter
    @scooter = current_user.scooters.find(params[:id])
  end

  def ensure_owner!
    unless current_user.owner_of?(@scooter)
      redirect_to scooters_path, alert: "You are not authorized to perform this action."
    end
  end

  def scooter_params
    params.require(:scooter).permit(:name, :vin, :color, :imei)
  end

  def handle_command_result(result, command_name)
    if result.success?
      redirect_to @scooter, notice: "#{command_name} command sent."
    else
      redirect_to @scooter, alert: "Failed to send #{command_name.downcase} command: #{result.error}"
    end
  end
end
