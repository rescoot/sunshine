class Admin::UnuRequestsController < Admin::ApplicationController
  def index
    @requests = UnuRequest.order(created_at: :desc).page(params[:page]).per(50)
  end

  def show
    @request = UnuRequest.find(params[:id])
  end
end
