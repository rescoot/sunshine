class ScootersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_scooter, except: [ :index, :new, :create ]
  before_action :ensure_owner!, only: [ :edit, :update, :destroy ]

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
    redirect_to scooters_url, notice: "Scooter was successfully removed."
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

    if result.success?
      notice = result.enqueued ? "Lock command enqueued for when scooter comes online." : "Lock command sent."
      redirect_to @scooter, notice: notice
    else
      redirect_to @scooter, alert: "Failed to send lock command: #{result.error}"
    end
  end

  def unlock
    result = ScooterCommandService.new(@scooter).send_command("unlock")

    if result.success?
      notice = result.enqueued ? "Unlock command enqueued for when scooter comes online." : "Unlock command sent."
      redirect_to @scooter, notice: notice
    else
      redirect_to @scooter, alert: "Failed to send unlock command: #{result.error}"
    end
  end

  def blinkers
    state = params[:state].presence_in(Scooter::BLINKER_STATES) || "off"
    result = ScooterCommandService.new(@scooter).send_command("blinkers", state: state)

    if result.success?
      notice = result.enqueued ? "Blinkers command enqueued for when scooter comes online." : "Blinkers set to #{state}."
      redirect_to @scooter, notice: notice
    else
      redirect_to @scooter, alert: "Failed to set blinkers: #{result.error}"
    end
  end

  def honk
    result = ScooterCommandService.new(@scooter).send_command("honk")

    if result.success?
      notice = result.enqueued ? "Honk command enqueued for when scooter comes online." : "Honk command sent."
      redirect_to @scooter, notice: notice
    else
      redirect_to @scooter, alert: "Failed to send honk command: #{result.error}"
    end
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

    if result.success?
      notice = result.enqueued ? "Sound command enqueued for when scooter comes online." : "Playing #{sound} sound."
      redirect_to @scooter, notice: notice
    else
      redirect_to @scooter, alert: "Failed to play sound: #{result.error}"
    end
  end

  def regenerating?
    false
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
    params.require(:scooter).permit(:name, :vin, :color)
  end

  def handle_command_result(result, command_name)
    if result.success?
      notice = result.enqueued ?
        "#{command_name} command enqueued for when scooter comes online." :
        "#{command_name} command sent."
      redirect_to @scooter, notice: notice
    else
      redirect_to @scooter, alert: "Failed to send #{command_name.downcase} command: #{result.error}"
    end
  end
end
