require_relative "../../app/services/mqtt_service"

Rails.application.config.after_initialize do
  Rails.logger.info "MQTT_ROLE=#{ENV.fetch("MQTT_ROLE", "").inspect}"
  Rails.logger.info "Is that == web? #{ENV.fetch("MQTT_ROLE", "") == "web"}"
  #MqttService.instance(web_mode: true) if ENV.fetch("MQTT_ROLE", "") == "web"
rescue => e
  Rails.logger.error(e)
end
