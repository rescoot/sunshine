module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      logger.debug "ActionCable attempting connection from #{request.origin} with cookies #{cookies.to_h.keys}..."
      self.current_user = find_verified_user
      logger.debug "Connected as #{current_user.email}"
    end

    private

    def find_verified_user
      if verified_user = env["warden"].user
        verified_user
      elsif verified_user = find_user_from_cookie
        verified_user
      elsif auth_token = request.params[:token] || request.headers["Authorization"]&.split(" ")&.last
        token = ApiToken.find_by(token_digest: Digest::SHA256.hexdigest(auth_token))
        token&.scooter&.owner
      end || reject_unauthorized_connection
    end

    def find_user_from_cookie
      if user_id = cookies.signed["user.id"]
        User.find_by(id: user_id)
      end
    end
  end
end
