require_relative "../../app/services/mqtt_service"

Rails.application.config.after_initialize do
  if ARGV.length >= 2 && ARGV[-2] == "./bin/rails" && ARGV[-1] == "server"
    Rails.logger.info("Running under rails server")
  else
    Rails.logger.info("Not running under rails server")
  end
  MqttService.instance(web_mode: true) if ENV.fetch("MQTT_ROLE", "") == "web"
rescue => e
  Rails.logger.error(e)
end
