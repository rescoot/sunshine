class Admin::UnuUplinkRequestsController < Admin::ApplicationController
  def index
    @requests = RawMessage.order(created_at: :desc).page(params[:page]).per(50)
  end

  def show
    @request = RawMessage.find(params[:id])
  end
end
