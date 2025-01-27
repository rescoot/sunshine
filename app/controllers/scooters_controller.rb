class ScootersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_scooter, except: [ :index, :new, :create ]
  before_action :ensure_owner!, only: [ :edit, :update, :destroy ]

  def index
    @scooters = current_user.scooters
  end

  def show
    @trips = @scooter.trips.order(started_at: :desc).limit(10)

    respond_to do |format|
      format.html
      format.turbo_stream
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

  # Remote control actions
  def lock
    result = ScooterCommandService.new(@scooter).send_command("lock")

    if result.success?
      redirect_to @scooter, notice: "Lock command sent."
    else
      redirect_to @scooter, alert: "Failed to send lock command: #{result.error}"
    end
  end

  def unlock
    result = ScooterCommandService.new(@scooter).send_command("unlock")

    if result.success?
      redirect_to @scooter, notice: "Unlock command sent."
    else
      redirect_to @scooter, alert: "Failed to send unlock command: #{result.error}"
    end
  end

  def blinkers
    state = params[:state].presence_in(Scooter::BLINKER_STATES) || "off"
    result = ScooterCommandService.new(@scooter).send_command("blinkers", state: state)

    if result.success?
      redirect_to @scooter, notice: "Blinkers set to #{state}."
    else
      redirect_to @scooter, alert: "Failed to set blinkers: #{result.error}"
    end
  end

  def honk
    result = ScooterCommandService.new(@scooter).send_command("honk")

    if result.success?
      redirect_to @scooter, notice: "Honk command sent."
    else
      redirect_to @scooter, alert: "Failed to send honk command: #{result.error}"
    end
  end

  def play_sound
    sound = params[:sound].presence_in([ "find_me", "alarm", "chirp" ]) || "chirp"
    result = ScooterCommandService.new(@scooter).send_command("play_sound", sound: sound)

    if result.success?
      redirect_to @scooter, notice: "Playing #{sound} sound."
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
end
