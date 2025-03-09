class AccountsController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = current_user
    @user_preference = current_user.user_preference || current_user.build_user_preference
    @api_tokens = current_user.api_tokens.user_tokens
  end

  def edit
    @user = current_user
  end

  def update
    @user = current_user
    @user_preference = current_user.user_preference || current_user.build_user_preference

    # Only require password if user is trying to change it
    if params[:user][:password].blank?
      params[:user].delete(:password)
      params[:user].delete(:password_confirmation)
    end

    # Handle avatar removal
    if params[:user][:remove_avatar] == "1"
      @user.avatar.purge
    end

    # Handle avatar upload
    if params[:user][:avatar].present?
      @user.avatar.attach(params[:user][:avatar])
    end

    # Update user preferences if provided
    if params[:user_preference].present?
      @user_preference.update(user_preference_params)
    end

    if @user.update(user_params)
      bypass_sign_in(@user)
      respond_to do |format|
        format.html { redirect_to account_path, notice: "Account updated successfully." }
        format.turbo_stream { redirect_to account_path, notice: "Account updated successfully." }
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.turbo_stream { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    current_user.destroy
    redirect_to root_path, notice: "Account deleted."
  end

  def update_landing_page
    @user_preference = current_user.user_preference || current_user.build_user_preference

    if @user_preference.update(landing_page_params)
      redirect_to account_path, notice: "Default landing page updated successfully."
    else
      redirect_to account_path, alert: "Could not update landing page preference."
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :avatar, :locale)
  end

  def user_preference_params
    params.require(:user_preference).permit(:default_landing_page)
  end

  def landing_page_params
    params.require(:user_preference).permit(:default_landing_page)
  end
end
