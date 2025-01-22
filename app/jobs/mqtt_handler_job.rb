class MqttHandlerJob < ApplicationJob
  queue_as :default

  def perform(*args)
    mqtt_handler = MqttHandler.instance
  end
end
