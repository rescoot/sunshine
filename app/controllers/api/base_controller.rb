class Api::BaseController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :authenticate_token!

  private

  def authenticate_token!
    token = request.headers["Authorization"]&.split(" ")&.last
    return head :unauthorized unless token

    digest = Digest::SHA256.hexdigest(token)
    @api_token = ApiToken.user_tokens.find_by(token_digest: digest)

    return head :unauthorized unless @api_token
    @api_token.touch(:last_used_at)
    @current_user = @api_token.user
  end

  def current_user
    @current_user
  end
end
