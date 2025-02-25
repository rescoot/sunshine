class Admin::UnuUplinkRequestsController < Admin::ApplicationController
  def index
    @requests = RawMessage.includes(:scooter).order(created_at: :desc)

    # Filter by IMEI
    @requests = @requests.where(imei: params[:imei]) if params[:imei].present?

    # Filter by type (topic)
    @requests = @requests.where("topic LIKE ?", "%#{params[:type]}%") if params[:type].present?

    # Filter by scooter
    @requests = @requests.where(scooter_id: params[:scooter_id]) if params[:scooter_id].present?

    # Filter by date range
    @requests = @requests.where("created_at >= ?", params[:start_date]) if params[:start_date].present?
    @requests = @requests.where("created_at <= ?", params[:end_date].to_date.end_of_day) if params[:end_date].present?

    # Paginate results
    @requests = @requests.page(params[:page]).per(50)
  end

  def show
    @request = RawMessage.find(params[:id])
  end
end
