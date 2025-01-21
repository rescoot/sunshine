class Api::BaseController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :authenticate_token!

  private

  def authenticate_token!
    token = request.headers["Authorization"]&.split(" ")&.last
    return head :unauthorized unless token

    digest = Digest::SHA256.hexdigest(token)
    @api_token = ApiToken.find_by(token_digest: digest)

    return head :unauthorized unless @api_token
    @api_token.touch(:last_used_at)
    @current_scooter = @api_token.scooter
  end

  def current_scooter
    @current_scooter
  end
end
