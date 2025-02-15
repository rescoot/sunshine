class MqttAuthService
  DYNSEC_USER_PREFIX = "radio-gaga"
  CONTROL_TOPIC = "$CONTROL/dynamic-security/v1"
  RESPONSE_TOPIC = "$CONTROL/dynamic-security/v1/response"

  def self.provision_scooter(scooter, token)
    new.provision_scooter(scooter, token)
  end

  def self.revoke_scooter(scooter)
    new.revoke_scooter(scooter)
  end

  def self.setup_imei_auth(scooter)
    new.setup_imei_auth(scooter) if scooter.imei.present?
  end

  def setup_imei_auth(scooter)
    return unless scooter.imei.present?

    # Create IMEI client
    response = publish_control_and_wait({
      command: "createClient",
      username: scooter.imei,
      password: scooter.imei,
      clientid: scooter.imei,
      textname: "UNU #{scooter.imei}",
      textdescription: "UNU scooter uplink for #{scooter.imei}",
      roles: []
    })

    return false unless response["response"] == "success"

    # Create role if doesn't exist
    response = publish_control_and_wait({
      command: "createRole",
      rolename: "unu_uplink",
      textname: "UNU Uplink",
      textdescription: "Role for UNU scooter uplink clients"
    })

    # Add pattern ACL to the role
    response = publish_control_and_wait({
      command: "addRoleACL",
      rolename: "unu_uplink",
      acltype: "publishPattern",
      topic: "#{scooter.imei}/#",
      priority: 0,
      allow: true
    })

    return false unless response["response"] == "success"

    # Add role to client
    response = publish_control_and_wait({
      command: "addClientRole",
      username: scooter.imei,
      rolename: "unu_uplink",
      priority: 0
    })

    response["response"] == "success"
  end

  def revoke_scooter(scooter)
    username = scooter.vin
    response = publish_control_and_wait({
      command: "deleteClient",
      username: username
    })

    # Also remove IMEI auth if present
    if scooter.imei.present?
      response = publish_control_and_wait({
        command: "deleteClient",
        username: scooter.imei
      })
    end

    response["response"] == "success"
  end

  def ensure_scooter_role
    # First, create the role
    response = publish_control_and_wait({
      command: "createRole",
      rolename: "scooter",
      textname: "Scooter Device Role",
      textdescription: "Default role for scooter devices"
    })

    # Define ACLs for the role
    acl_configs = [
      {
        command: "addRoleACL",
        rolename: "scooter",
        acltype: "publishClientSend",
        topic: "scooters/%u/commands",
        priority: 1,
        allow: true
      },
      {
        command: "addRoleACL",
        rolename: "scooter",
        acltype: "publishClientSend",
        topic: "scooters/%u/telemetry",
        priority: 1,
        allow: true
      },
      {
        command: "addRoleACL",
        rolename: "scooter",
        acltype: "publishClientSend",
        topic: "scooters/%u/acks",
        priority: 1,
        allow: true
      },
      {
        command: "addRoleACL",
        rolename: "scooter",
        acltype: "publishClientSend",
        topic: "scooters/%u/status",
        priority: 1,
        allow: true
      },
      {
        command: "addRoleACL",
        rolename: "scooter",
        acltype: "publishClientSend",
        topic: "scooters/%u/data",
        priority: 1,
        allow: true
      },
      {
        command: "addRoleACL",
        rolename: "scooter",
        acltype: "publishClientReceive",
        topic: "scooters/%u/commands",
        priority: 1,
        allow: true
      }
    ]

    # Add each ACL
    acl_configs.each do |acl_config|
      response = publish_control_and_wait(acl_config)
      return false unless response["response"] == "success" or response["error"] =~ /already exists/
    end

    true
  end

  def provision_scooter(scooter, token)
    # Ensure the role exists with correct ACLs
    return false unless ensure_scooter_role

    # Create client directly with the role
    response = publish_control_and_wait({
      command: "createClient",
      username: scooter.vin,
      password: token,
      clientid: "radio-gaga-#{scooter.vin}",
      textname: "Scooter #{scooter.vin}",
      textdescription: "Radio Gaga client for #{scooter.vin}",
      roles: [ { rolename: "scooter", priority: 0 } ]
    })

    response["response"] == "success"
  end

  def subscribe_to_response(correlation_id, &block)
    MqttService.instance.subscribe_to_response do |topic, message|
      # Check if the correlation ID matches
      if message["correlationData"] == correlation_id
        block.call(message)
      end
    end
  end

  def publish_control_and_wait(payload)
    correlation_id = SecureRandom.uuid
    payload = payload.merge(correlationData: correlation_id)

    response = nil
    subscription = subscribe_to_response(correlation_id) do |resp|
      response = resp
    end

    MqttService.instance.publish_control(CONTROL_TOPIC, payload)

    # Wait for response with timeout
    start_time = Time.current
    while response.nil? && Time.current - start_time < 5.seconds
      sleep 0.1
    end

    MqttService.instance.unsubscribe_from_response(subscription)

    if response.nil?
      Rails.logger.error "Timeout waiting for MQTT control response: #{payload}"
      { "response" => "error", "error" => "timeout" }
    else
      # Normalize the response to handle both success and error cases
      if response["error"]
        { "response" => "error", "error" => response["error"] }
      else
        { "response" => "success", "details" => response }
      end
    end
  end
end
