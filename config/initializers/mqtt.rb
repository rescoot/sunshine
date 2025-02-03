require_relative "../../app/services/mqtt_service"

Rails.application.config.after_initialize do
  MqttService.instance(web_mode: true) unless ENV.fetch("SECRET_KEY_BASE_DUMMY")
rescue => e
  Rails.logger.error(e)
end
