class ApplicationController < ActionController::Base
  include MandatoryOtp
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :name ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :name ])
  end

  def ensure_admin!
    unless current_user.admin?
      redirect_to root_path, alert: "Not authorized"
    end
  end

  def after_sign_in_path_for(resource)
    stored_location_for(resource) || dashboard_path
  end

  def after_sign_out_path_for(_scope)
    root_path
  end
end
