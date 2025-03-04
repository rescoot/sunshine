class ProcessQueuedCommandsJob < ApplicationJob
  queue_as :default

  # Process queued commands for a specific scooter
  # If scooter_id is nil, process all queued commands
  def perform(scooter_id = nil)
    if scooter_id
      # Process commands for a specific scooter
      scooter = Scooter.find_by(id: scooter_id)
      return unless scooter&.is_online?

      process_commands_for_scooter(scooter)
    else
      # Process commands for all online scooters
      Scooter.where(is_online: true).find_each do |scooter|
        process_commands_for_scooter(scooter)
      end
    end
  end

  private

  def process_commands_for_scooter(scooter)
    # Find all queued commands for this scooter that haven't expired
    queued_commands = scooter.scooter_commands
                            .where(queued: true, status: "pending")
                            .where("expires_at > ?", Time.current)
                            .order(created_at: :asc)

    if queued_commands.any?
      Rails.logger.info "Processing #{queued_commands.count} queued commands for scooter #{scooter.id} (#{scooter.vin})"
    end

    queued_commands.each do |command|
      # Try to send the command
      begin
        Rails.logger.info "Processing queued command #{command.id} (#{command.command}) for scooter #{scooter.id}"
        result = ScooterCommandService.new(scooter, command.user)
                                     .send_queued_command(command)

        if result.success?
          # Mark as processed
          command.update(
            queued: false,
            status: "sent",
            processed_at: Time.current
          )
          Rails.logger.info "Successfully processed queued command #{command.id}"
        else
          Rails.logger.error "Failed to process queued command #{command.id}: #{result.error}"
        end
      rescue => e
        Rails.logger.error "Error processing queued command #{command.id}: #{e.message}"
      end
    end
  end
end
