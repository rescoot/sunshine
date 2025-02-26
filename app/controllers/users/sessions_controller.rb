class Users::SessionsController < Devise::SessionsController
  prepend_before_action :check_otp_required, only: [ :create ]

  def check_otp_required
    user = User.find_by(email: params[:user][:email])
    return unless user && user.valid_password?(params[:user][:password]) && user.otp_enabled?

    # Store user ID in session for OTP verification
    session[:otp_user_id] = user.id

    # Redirect to OTP verification page
    redirect_to users_otp_verification_path
  end
end
