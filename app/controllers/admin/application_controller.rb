class Admin::ApplicationController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin!

  private

  def ensure_admin!
    unless current_user.id == 1
      redirect_to root_path, alert: "Not authorized"
    end
  end
end
