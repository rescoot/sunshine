class TwoFactorAuthController < ApplicationController
  include Devise::Controllers::Helpers

  before_action :authenticate_user!
  before_action :check_otp_enabled, only: [ :destroy ]
  before_action :check_otp_disabled, only: [ :new, :create ]

  def new
    # Generate OTP secrets if they don't exist
    current_user.populate_otp_secrets! if current_user.otp_auth_secret.nil?

    # Generate the provisioning URI for QR code
    @provisioning_uri = current_user.otp_provisioning_uri

    # Get recovery codes
    @recovery_codes = current_user.next_otp_recovery_tokens
  end

  def create
    # Verify the OTP code provided by the user
    if current_user.validate_otp_token(params[:otp_attempt])
      # Enable OTP for the user
      current_user.enable_otp!

      flash[:notice] = "Two-factor authentication has been enabled successfully."
      redirect_to account_path
    else
      flash.now[:alert] = "Invalid verification code. Please try again."
      # Re-generate the provisioning URI for QR code
      @provisioning_uri = current_user.otp_provisioning_uri
      @recovery_codes = current_user.next_otp_recovery_tokens
      render :new
    end
  end

  def destroy
    # Check if password is provided and valid
    if params[:password].present? && current_user.valid_password?(params[:password])
      # Disable OTP for the user
      current_user.disable_otp!
      current_user.clear_otp_fields!

      flash[:notice] = "Two-factor authentication has been disabled."
      redirect_to account_path
    else
      flash[:alert] = "Invalid password. Please try again."
      render :confirm_disable
    end
  end

  def confirm_disable
    # Show confirmation page with password field
  end

  private

  def check_otp_enabled
    unless current_user.otp_enabled?
      flash[:alert] = "Two-factor authentication is not enabled."
      redirect_to account_path
    end
  end

  def check_otp_disabled
    if current_user.otp_enabled?
      flash[:alert] = "Two-factor authentication is already enabled."
      redirect_to account_path
    end
  end
end
