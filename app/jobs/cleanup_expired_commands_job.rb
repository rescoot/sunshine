class CleanupExpiredCommandsJob < ApplicationJob
  queue_as :default

  def perform
    # Clean up expired commands
    expired_count = ScooterCommand.where(queued: true)
                                 .where("expires_at <= ?", Time.current)
                                 .update_all(
                                   queued: false,
                                   status: "expired",
                                   processed_at: Time.current
                                 )

    Rails.logger.info "Cleaned up #{expired_count} expired commands"
  end
end
