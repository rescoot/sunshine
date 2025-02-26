class LocalesController < ApplicationController
  def update
    locale = params[:locale].presence

    # If the user is signed in, update their locale preference
    if user_signed_in? && (locale.blank? || I18n.available_locales.map(&:to_s).include?(locale))
      current_user.update(locale: locale) unless current_user.locale == locale
    end

    # Store in session for guests
    session[:locale] = locale

    # Redirect back to the referring page
    redirect_back(fallback_location: root_path)
  end
end
