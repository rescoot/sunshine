module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      logger.debug("ApplicationCable::connect #{request.params}")
      logger.debug(cookies)
      self.current_user = find_verified_user
      logger.debug(self.current_user)
    end

    private

    def find_verified_user
      Rails.logger.debug("find_verified_user")
      return User.first
        # if user = User.find_by(vin: request.params[:device_id])
        #   # TODO: Add proper API key validation
        #   scooter
        # elsif verified_user = env["warden"].user
        #   verified_user
        # else
        reject_unauthorized_connection
      # end
    end
  end
end
