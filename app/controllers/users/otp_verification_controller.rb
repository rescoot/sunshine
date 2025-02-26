class Users::OtpVerificationController < ApplicationController
  before_action :check_otp_user_session

  def show
    @user = User.find(session[:otp_user_id])
  end

  def create
    @user = User.find(session[:otp_user_id])

    # Check if the token is a valid OTP token or a valid recovery token
    if @user.validate_otp_token(params[:otp_attempt]) ||
       @user.validate_otp_token(params[:otp_attempt], recovery: true)
      # Clear OTP session data
      session.delete(:otp_user_id)

      # Sign in the user
      sign_in(:user, @user)

      # Set trusted device if requested
      otp_set_trusted_device_for(@user) if params[:trust_device] == "1" && trusted_devices_enabled?

      # Redirect to the stored location or default
      redirect_to stored_location_for(:user) || root_path, notice: "Signed in successfully."
    else
      flash.now[:alert] = "Invalid verification code. Please try again."
      render :show
    end
  end

  private

  def check_otp_user_session
    redirect_to new_user_session_path unless session[:otp_user_id].present?
  end

  def trusted_devices_enabled?
    @user.class.otp_trust_persistence.present?
  end
end
