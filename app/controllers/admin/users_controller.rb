# app/controllers/admin/users_controller.rb
class Admin::UsersController < Admin::ApplicationController
  before_action :set_user, only: [ :show, :edit, :update, :destroy ]

  def index
    @users = User.includes(:scooters)

    # Search filters
    @users = @users.where("LOWER(name) LIKE ?", "%#{params[:name].downcase}%") if params[:name].present?
    @users = @users.where("LOWER(email) LIKE ?", "%#{params[:email].downcase}%") if params[:email].present?
    @users = @users.where(is_admin: params[:admin]) if params[:admin].present?

    @users = @users.order(created_at: :desc).page(params[:page])
  end

  def show
  end

  def new
    @user = User.new
  end

  def edit
    @feature_flags = FeatureFlag.all.order(:name)
    @user_feature_flags = @user.user_feature_flags.includes(:feature_flag)
  end

  def create
    @user = User.new(user_params)

    if @user.save
      redirect_to admin_users_path, notice: "User was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @user.update(user_params)
      redirect_to admin_users_path, notice: "User was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @user.destroy
    redirect_to admin_users_path, notice: "User was successfully deleted.", status: :see_other
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:name, :email, :is_admin, :password, :password_confirmation)
  end
end
