Rails.application.config.to_prepare do
  Rails.logger.info "Initializing MQTT Handler..."
  MqttHandler.instance
rescue => e
  Rails.logger.error "Failed to initialize MQTT Handler: #{e.message}"
  Rails.logger.error e.backtrace.join("\n")
end
