# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: unu/v1/scooter_state.proto

require "google/protobuf"

require "google/protobuf/timestamp_pb"
Google::Protobuf::DescriptorPool.generated_pool.build do
  add_file("unu/v1/scooter_state.proto", syntax: :proto3) do
    add_message "protos.unu.v1.ScooterStateBulk" do
      repeated :states, :message, 1, "protos.unu.v1.ScooterState"
    end
    add_message "protos.unu.v1.ScooterState" do
      optional :ts, :message, 1, "google.protobuf.Timestamp"
      optional :seatbox, :message, 2, "protos.unu.v1.ScooterState.Seatbox"
      optional :handlebar, :message, 3, "protos.unu.v1.ScooterState.Handlebar"
      optional :mode, :enum, 4, "protos.unu.v1.ScooterState.ScooterMode"
      optional :main_battery_0, :message, 5, "protos.unu.v1.ScooterState.MainBattery"
      optional :main_battery_1, :message, 6, "protos.unu.v1.ScooterState.MainBattery"
      optional :cb_battery, :message, 7, "protos.unu.v1.ScooterState.CBBattery"
      optional :aux_battery, :message, 8, "protos.unu.v1.ScooterState.AuxBattery"
      optional :versions, :message, 9, "protos.unu.v1.ScooterState.FirmwareVersions"
      proto3_optional :odometer, :uint32, 10
      optional :network, :message, 11, "protos.unu.v1.ScooterState.Network"
      optional :drive_mode, :enum, 12, "protos.unu.v1.ScooterState.ScooterDriveMode"
      optional :power_mode, :enum, 13, "protos.unu.v1.ScooterState.ScooterPowerMode"
      optional :scooter_protobuf_version, :string, 14
      optional :serial_numbers, :message, 15, "protos.unu.v1.ScooterState.SerialNumbers"
      optional :ota, :message, 16, "protos.unu.v1.ScooterState.Ota"
      optional :bluetooth, :message, 17, "protos.unu.v1.ScooterState.Bluetooth"
      optional :location, :message, 18, "protos.unu.v1.ScooterState.Location"
    end
    add_message "protos.unu.v1.ScooterState.Seatbox" do
      optional :open, :bool, 1
    end
    add_message "protos.unu.v1.ScooterState.Handlebar" do
      optional :locked, :bool, 1
      optional :in_place_position, :bool, 2
    end
    add_message "protos.unu.v1.ScooterState.MainBattery" do
      optional :present, :bool, 1
      optional :state, :enum, 2, "protos.unu.v1.ScooterState.MainBatteryState"
      proto3_optional :charge, :uint32, 3
      proto3_optional :cycle_count, :uint32, 4
      optional :manufacturing_date, :message, 5, "google.protobuf.Timestamp"
      optional :serial_number, :string, 6
      optional :fw_version, :string, 7
      proto3_optional :state_of_health, :uint32, 8
    end
    add_message "protos.unu.v1.ScooterState.CBBattery" do
      optional :present, :bool, 1
      proto3_optional :charge, :uint32, 2
      optional :state, :enum, 3, "protos.unu.v1.ScooterState.CBBatteryState"
      proto3_optional :cycle_count, :uint32, 4
      optional :serial_number, :string, 5
      proto3_optional :state_of_health, :uint32, 6
      proto3_optional :cell_voltage, :uint32, 7
    end
    add_message "protos.unu.v1.ScooterState.AuxBattery" do
      proto3_optional :voltage, :int32, 1
      proto3_optional :charge, :uint32, 2
      optional :charge_status, :enum, 3, "protos.unu.v1.ScooterState.AuxChargeStatus"
    end
    add_message "protos.unu.v1.ScooterState.FirmwareVersions" do
      optional :dbc_version, :string, 1
      optional :mdb_version, :string, 2
      optional :nrf_fw_version, :string, 3
      optional :engine_ecu_version, :string, 4
      optional :environment, :string, 5
      optional :ble_mac_address, :string, 6
    end
    add_message "protos.unu.v1.ScooterState.Network" do
      optional :ip, :string, 1
      optional :connection_technology, :string, 2
    end
    add_message "protos.unu.v1.ScooterState.SerialNumbers" do
      optional :mdb_cpu_sn, :string, 1
      optional :dbc_cpu_sn, :string, 2
    end
    add_message "protos.unu.v1.ScooterState.Ota" do
      optional :tag, :string, 1
      optional :system, :enum, 2, "protos.unu.v1.ScooterState.OtaSystem"
      optional :migration, :enum, 3, "protos.unu.v1.ScooterState.OtaMigrationStatus"
    end
    add_message "protos.unu.v1.ScooterState.Bluetooth" do
      optional :mac_address, :string, 1
      optional :pin_code, :string, 2
    end
    add_message "protos.unu.v1.ScooterState.Location" do
      optional :latitude, :double, 1
      optional :longitude, :double, 2
      optional :altitude, :double, 3
      optional :ts, :message, 4, "google.protobuf.Timestamp"
    end
    add_enum "protos.unu.v1.ScooterState.ScooterMode" do
      value :SCOOTER_MODE_UNSPECIFIED, 0
      value :SCOOTER_MODE_READY_TO_DRIVE, 1
      value :SCOOTER_MODE_PARKED, 2
      value :SCOOTER_MODE_STANDBY, 3
      value :SCOOTER_MODE_STANDBY_SUSPEND, 4
      value :SCOOTER_MODE_STANDBY_HIBERNATION, 5
    end
    add_enum "protos.unu.v1.ScooterState.MainBatteryState" do
      value :MAIN_BATTERY_STATE_UNSPECIFIED, 0
      value :MAIN_BATTERY_STATE_UNKNOWN, 1
      value :MAIN_BATTERY_STATE_ASLEEP, 2
      value :MAIN_BATTERY_STATE_IDLE, 3
      value :MAIN_BATTERY_STATE_ACTIVE, 4
    end
    add_enum "protos.unu.v1.ScooterState.CBBatteryState" do
      value :CB_BATTERY_STATE_UNSPECIFIED, 0
      value :CB_BATTERY_STATE_CHARGING, 1
      value :CB_BATTERY_STATE_NOT_CHARGING, 2
    end
    add_enum "protos.unu.v1.ScooterState.AuxChargeStatus" do
      value :AUX_CHARGE_STATUS_UNSPECIFIED, 0
      value :AUX_CHARGE_STATUS_NOT_CHARGING, 1
      value :AUX_CHARGE_STATUS_FLOAT_CHARGE, 2
      value :AUX_CHARGE_STATUS_ABSORPTION_CHARGE, 3
      value :AUX_CHARGE_STATUS_BULK_CHARGE, 4
    end
    add_enum "protos.unu.v1.ScooterState.ScooterDriveMode" do
      value :SCOOTER_DRIVE_MODE_UNSPECIFIED, 0
      value :SCOOTER_DRIVE_MODE_DRIVE, 1
      value :SCOOTER_DRIVE_MODE_PARK, 2
      value :SCOOTER_DRIVE_MODE_STANDBY, 3
    end
    add_enum "protos.unu.v1.ScooterState.ScooterPowerMode" do
      value :SCOOTER_POWER_MODE_UNSPECIFIED, 0
      value :SCOOTER_POWER_MODE_RUNNING, 1
      value :SCOOTER_POWER_MODE_SUSPEND, 2
      value :SCOOTER_POWER_MODE_HIBERNATION, 3
      value :SCOOTER_POWER_MODE_MANUAL_HIBERNATION, 4
      value :SCOOTER_POWER_MODE_TIME_BASED_HIBERNATION, 5
    end
    add_enum "protos.unu.v1.ScooterState.OtaSystem" do
      value :OTA_SYSTEM_UNSPECIFIED, 0
      value :OTA_SYSTEM_HERE, 1
      value :OTA_SYSTEM_FOUNDRIES, 2
    end
    add_enum "protos.unu.v1.ScooterState.OtaMigrationStatus" do
      value :OTA_MIGRATION_STATUS_UNSPECIFIED, 0
      value :OTA_MIGRATION_STATUS_WAITING_PREREQUISITE, 1
      value :OTA_MIGRATION_STATUS_PREPARING_MIGRATION, 2
      value :OTA_MIGRATION_STATUS_FOUNDRIES_PROVISIONING, 3
      value :OTA_MIGRATION_STATUS_FOUNDRIES_PROVISIONING_FAILED, 4
      value :OTA_MIGRATION_STATUS_CONFIGURING_SERVICES, 5
      value :OTA_MIGRATION_STATUS_RESTORING_SERVICES, 6
      value :OTA_MIGRATION_STATUS_SUCCESSFUL, 7
      value :OTA_MIGRATION_STATUS_FAILED, 8
    end
  end
end

module Protos
  module Unu
    module V1
      ScooterStateBulk = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("protos.unu.v1.ScooterStateBulk").msgclass
      ScooterState = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("protos.unu.v1.ScooterState").msgclass
      ScooterState::Seatbox = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("protos.unu.v1.ScooterState.Seatbox").msgclass
      ScooterState::Handlebar = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("protos.unu.v1.ScooterState.Handlebar").msgclass
      ScooterState::MainBattery = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("protos.unu.v1.ScooterState.MainBattery").msgclass
      ScooterState::CBBattery = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("protos.unu.v1.ScooterState.CBBattery").msgclass
      ScooterState::AuxBattery = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("protos.unu.v1.ScooterState.AuxBattery").msgclass
      ScooterState::FirmwareVersions = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("protos.unu.v1.ScooterState.FirmwareVersions").msgclass
      ScooterState::Network = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("protos.unu.v1.ScooterState.Network").msgclass
      ScooterState::SerialNumbers = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("protos.unu.v1.ScooterState.SerialNumbers").msgclass
      ScooterState::Ota = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("protos.unu.v1.ScooterState.Ota").msgclass
      ScooterState::Bluetooth = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("protos.unu.v1.ScooterState.Bluetooth").msgclass
      ScooterState::Location = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("protos.unu.v1.ScooterState.Location").msgclass
      ScooterState::ScooterMode = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("protos.unu.v1.ScooterState.ScooterMode").enummodule
      ScooterState::MainBatteryState = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("protos.unu.v1.ScooterState.MainBatteryState").enummodule
      ScooterState::CBBatteryState = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("protos.unu.v1.ScooterState.CBBatteryState").enummodule
      ScooterState::AuxChargeStatus = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("protos.unu.v1.ScooterState.AuxChargeStatus").enummodule
      ScooterState::ScooterDriveMode = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("protos.unu.v1.ScooterState.ScooterDriveMode").enummodule
      ScooterState::ScooterPowerMode = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("protos.unu.v1.ScooterState.ScooterPowerMode").enummodule
      ScooterState::OtaSystem = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("protos.unu.v1.ScooterState.OtaSystem").enummodule
      ScooterState::OtaMigrationStatus = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("protos.unu.v1.ScooterState.OtaMigrationStatus").enummodule
    end
  end
end
