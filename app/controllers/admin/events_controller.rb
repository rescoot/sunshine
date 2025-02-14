class Admin::EventsController < Admin::ApplicationController
  before_action :set_scooter, only: [ :index, :show ]

  def index
    @events = if @scooter
      @scooter.scooter_events
    else
      ScooterEvent.includes(:scooter)
    end

    # Search filters
    @events = @events.where(event_type: params[:event_type]) if params[:event_type].present?
    @events = @events.where("created_at >= ?", params[:start_date]) if params[:start_date].present?
    @events = @events.where("created_at <= ?", params[:end_date]) if params[:end_date].present?
    @events = @events.joins(:scooter).where("LOWER(scooters.name) LIKE ?", "%#{params[:scooter_name].downcase}%") if params[:scooter_name].present?

    @events = @events.order(created_at: :desc).page(params[:page])
  end


  def show
    @event = ScooterEvent.find(params[:id])
  end

  private

  def set_scooter
    @scooter = Scooter.find(params[:scooter_id]) if params[:scooter_id]
  end
end
