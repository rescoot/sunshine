module MandatoryOtp
  extend ActiveSupport::Concern

  included do
    before_action :ensure_mandatory_otp_setup, if: :user_signed_in?
  end

  protected

  def ensure_mandatory_otp_setup
    return unless current_user.is_admin?
    return if current_user.otp_enabled?
    return unless current_user.otp_mandatory?

    # Skip if we're already on the 2FA setup page or in the process of setting it up
    return if controller_name == "two_factor_auth" && [ "new", "create" ].include?(action_name)

    # Redirect to 2FA setup with a warning
    flash[:alert] = "As an admin, you must set up two-factor authentication for enhanced security."
    redirect_to new_two_factor_auth_path
  end
end
