module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_scooter

    def connect
      self.current_scooter = find_verified_scooter
      logger.debug(self.current_scooter.id)
    end

    private

    def find_verified_scooter
      if scooter = Scooter.find_by(vin: request.params[:device_id])
        # TODO: Add proper API key validation
        scooter
      else
        reject_unauthorized_connection
      end
    end
  end
end
