class ApplicationController < ActionController::Base
  include MandatoryOtp
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :set_locale
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  # Set the locale based on user preference or browser headers
  def set_locale
    # If a locale param is provided, use it and store it in the session
    if params[:locale].present?
      # If the user is signed in, update their locale preference
      if user_signed_in? && (params[:locale].blank? || I18n.available_locales.map(&:to_s).include?(params[:locale]))
        current_user.update(locale: params[:locale]) unless current_user.locale == params[:locale]
      end

      # Store in session for guests
      session[:locale] = params[:locale]
    end

    # Determine the locale to use
    I18n.locale = if user_signed_in? && current_user.locale.present?
                    current_user.locale
    elsif session[:locale].present?
                    session[:locale]
    else
                    extract_locale_from_accept_language_header || I18n.default_locale
    end
  end

  # Extract locale from browser Accept-Language header
  def extract_locale_from_accept_language_header
    return nil unless request.env["HTTP_ACCEPT_LANGUAGE"]

    # Get the first locale from the Accept-Language header
    browser_locale = request.env["HTTP_ACCEPT_LANGUAGE"].scan(/^[a-z]{2}/).first

    # Map browser locale to our available locales
    case browser_locale
    when "de"
      "de_DE"
    when "en"
      "en"
    else
      nil
    end
  end

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
    # Check if there's a stored location from Devise (i.e., user was redirected to login)
    stored_location = stored_location_for(resource)
    return stored_location if stored_location.present?

    # If the user has a preference for landing page, use it
    if resource.user_preference&.default_landing_page.present?
      case resource.user_preference.default_landing_page
      when "dashboard"
        dashboard_path
      when "scooters"
        scooters_path
      when "last_used_scooter"
        # Find the user's most recently used scooter
        last_scooter = resource.scooters.joins(:trips)
                              .order("trips.started_at DESC")
                              .first
        last_scooter.present? ? scooter_path(last_scooter) : dashboard_path
      else
        dashboard_path
      end
    else
      # Default to dashboard if no preference is set
      dashboard_path
    end
  end

  def after_sign_out_path_for(_scope)
    root_path
  end
end
