module Api
  module V1
    class CommandsController < BaseController
      def receive
        ScooterChannel.broadcast_to(@current_scooter, command_params)
        head :ok
      end

      private

      def command_params
        params.require(:command).permit(:action, :params)
      end
    end
  end
end
