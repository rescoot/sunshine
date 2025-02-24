class TelemetryArchivalJob < ApplicationJob
  queue_as :background

  def perform
    Rails.logger.info "Starting telemetry archival job"
    result = TelemetryArchivalService.archive_old_telemetries
    Rails.logger.info "Telemetry archival completed: #{result[:message]}"
  end
end
