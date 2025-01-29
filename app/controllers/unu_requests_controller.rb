class UnuRequestsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin!

  def index
    @requests = UnuRequest.order(created_at: :desc).page(params[:page]).per(50)
  end

  def show
    @request = UnuRequest.find(params[:id])
  end

  private

  def ensure_admin!
    unless current_user.id == 1
      redirect_to root_path, alert: "Not authorized"
    end
  end
end
