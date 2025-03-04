class Admin::ScootersController < Admin::ApplicationController
  before_action :set_scooter, only: [ :show, :edit, :update, :destroy, :process_trips ]

  def index
    @scooters = Scooter.includes(:users, :user_scooters)

    # Search filters
    @scooters = @scooters.where("LOWER(name) LIKE ?", "%#{params[:name].downcase}%") if params[:name].present?
    @scooters = @scooters.where("LOWER(vin) LIKE ?", "%#{params[:vin].downcase}%") if params[:vin].present?
    @scooters = @scooters.where("LOWER(imei) LIKE ?", "%#{params[:imei].downcase}%") if params[:imei].present?
    @scooters = @scooters.where(color: params[:color]) if params[:color].present?
    @scooters = @scooters.where(is_online: params[:status] == "online") if params[:status].present?

    @scooters = @scooters.order(created_at: :desc).page(params[:page])
  end

  def show
    @telemetries = @scooter.telemetries.order(created_at: :desc).limit(100)
    @events = @scooter.scooter_events.order(created_at: :desc).limit(10)
    @users = @scooter.user_scooters.includes(:user)
    @available_users = User.where.not(id: @scooter.users.pluck(:id))
  end

  def new
    @scooter = Scooter.new
  end

  def edit
  end

  def create
    @scooter = Scooter.new(scooter_params)

    if @scooter.save
      if params[:owner_id].present?
        UserScooter.create!(
          user: User.find(params[:owner_id]),
          scooter: @scooter,
          role: "owner"
        )
      end
      redirect_to admin_scooters_path, notice: "Scooter was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @scooter.update(scooter_params)
      redirect_to admin_scooters_path, notice: "Scooter was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @scooter.destroy
    redirect_to admin_scooters_path, notice: "Scooter was successfully deleted.", status: :see_other
  end

  def process_trips
    processor = HistoricalTripProcessor.new(scooter_ids: [ @scooter.id ])
    stats = processor.process

    redirect_to admin_scooter_path(@scooter), notice: "Trip processing completed. Created #{stats[:valid_trips_created]} new trips."
  end

  private

  def set_scooter
    @scooter = Scooter.find(params[:id])
  end

  def scooter_params
    params.require(:scooter).permit(:name, :vin, :color, :imei)
  end
end

# app/controllers/admin/user_scooters_controller.rb
class Admin::UserScootersController < Admin::ApplicationController
  before_action :set_scooter

  def create
    @user_scooter = @scooter.user_scooters.build(user_scooter_params)

    if @user_scooter.save
      redirect_to admin_scooter_path(@scooter), notice: "User was successfully assigned."
    else
      redirect_to admin_scooter_path(@scooter), alert: "Failed to assign user."
    end
  end

  def destroy
    @user_scooter = @scooter.user_scooters.find(params[:id])
    @user_scooter.destroy
    redirect_to admin_scooter_path(@scooter), notice: "User was successfully unassigned."
  end

  private

  def set_scooter
    @scooter = Scooter.find(params[:scooter_id])
  end

  def user_scooter_params
    params.require(:user_scooter).permit(:user_id, :role)
  end
end
