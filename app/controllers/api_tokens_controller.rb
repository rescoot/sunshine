class ApiTokensController < ApplicationController
  before_action :authenticate_user!
  before_action :set_scooter
  before_action :ensure_owner!

  def create
    # Clear any existing tokens - one scooter, one token
    @scooter.api_token&.destroy
    @api_token = ApiToken.generate_for_scooter(@scooter)

    respond_to do |format|
      format.html do
        flash[:token] = @api_token.token
        redirect_to scooter_path(@scooter, token_id: @api_token.id)
      end
      format.turbo_stream do
        @token = @api_token.token
        render turbo_stream: [
          turbo_stream.update("api_token_section",
            partial: "scooters/api_token",
            locals: { scooter: @scooter, token: @token }
          )
        ]
      end
    end
  end

  def download_config
    @api_token = @scooter.api_token

    # Try to get token from different sources
    token = if params[:token_id].present?
      ApiToken.fetch_token(params[:token_id])
    else
      ApiToken.fetch_scooter_token(@scooter.id)
    end

    unless token
      flash[:error] = "Token expired. Please generate a new one."
      redirect_to scooter_path(@scooter) and return
    end

    config = @scooter.generate_config_with_token(token)

    send_data config.to_yaml,
      filename: "radio-gaga-#{@scooter.vin}.yml",
      type: "application/x-yaml",
      disposition: "attachment"
  end

  private

  def set_scooter
    @scooter = current_user.scooters.find(params[:scooter_id])
  end

  def ensure_owner!
    unless current_user.owner_of?(@scooter)
      redirect_to scooters_path, alert: "You are not authorized to perform this action."
    end
  end
end
