class PagesController < ApplicationController
  def index
    redirect_to dashboard_path if user_signed_in?
  end

  def about
  end

  def services
  end

  def contact
  end

  def privacy_policy
  end

  def legal_notice
  end

  def security
  end
end
