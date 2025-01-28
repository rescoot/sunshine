class Accounts::ApiTokensController < ApplicationController
  before_action :authenticate_user!

  def new
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def create
    default_name = "API Token #{Time.current.strftime('%Y-%m-%d %H:%M')}"
    @api_token = ApiToken.generate_for_user(current_user, name: params[:name] || default_name)
    flash[:api_token] = @api_token.token

    respond_to do |format|
      format.html { redirect_to account_path, notice: "API token generated." }
      format.turbo_stream {
        @api_tokens = current_user.api_tokens.user_tokens
        render turbo_stream: [
          turbo_stream.update("new_token_form", partial: "accounts/new_token_button"),
          turbo_stream.prepend("api_tokens_list",
            partial: "accounts/token_flash",
            locals: { token: @api_token.token }),
          turbo_stream.update("tokens_table",
            partial: "accounts/token_list",
            locals: { api_tokens: @api_tokens })
        ]
      }
    end
  end

  def destroy
    @api_token = current_user.api_tokens.user_tokens.find(params[:id])
    @api_token.destroy
    redirect_to account_path, notice: "API token revoked."
  end
end
