# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: unu/v1/command.proto

require "google/protobuf"

require "google/protobuf/timestamp_pb"
Google::Protobuf::DescriptorPool.generated_pool.build do
  add_file("unu/v1/command.proto", syntax: :proto3) do
    add_message "protos.unu.v1.ScooterConfig" do
      optional :location_disabled, :bool, 1
      optional :hibernation_timer, :int32, 2
    end
    add_message "protos.unu.v1.CommandRequest" do
      optional :command, :enum, 1, "protos.unu.v1.Command"
      optional :id, :string, 2
      oneof :data do
        optional :config, :message, 3, "protos.unu.v1.ScooterConfig"
      end
    end
    add_message "protos.unu.v1.CommandAcknowledgement" do
      optional :id, :string, 1
      optional :status, :enum, 2, "protos.unu.v1.CommandStatus"
      optional :ts, :message, 3, "google.protobuf.Timestamp"
      oneof :rejection do
        optional :precondition_failed, :enum, 4, "protos.unu.v1.PreconditionFailed"
        optional :other_reason, :string, 5
      end
    end
    add_enum "protos.unu.v1.Command" do
      value :COMMAND_UNSPECIFIED, 0
      value :COMMAND_PING_PONG, 1
      value :COMMAND_GO_TO_HIBERNATION, 2
      value :COMMAND_LOCK, 3
      value :COMMAND_UNLOCK, 4
      value :COMMAND_UPDATE_CONFIG, 5
    end
    add_enum "protos.unu.v1.CommandStatus" do
      value :COMMAND_STATUS_UNSPECIFIED, 0
      value :COMMAND_STATUS_PENDING, 1
      value :COMMAND_STATUS_EXECUTED, 2
      value :COMMAND_STATUS_EXECUTION_SCHEDULED, 3
      value :COMMAND_STATUS_EXECUTION_REJECTED, 4
      value :COMMAND_STATUS_EXECUTION_FAILED, 5
      value :COMMAND_STATUS_TIMED_OUT, 6
      value :COMMAND_STATUS_CANCELED, 7
    end
    add_enum "protos.unu.v1.PreconditionFailed" do
      value :PRECONDITION_FAILED_UNSPECIFIED, 0
      value :PRECONDITION_FAILED_SCOOTER_NOT_IN_PARKED_OR_SUSPEND, 1
      value :PRECONDITION_FAILED_NOT_IN_STANDBY, 2
      value :PRECONDITION_FAILED_HIBERNATION_PENDING, 3
      value :PRECONDITION_FAILED_SCOOTER_NOT_IN_PARKED, 4
      value :PRECONDITION_FAILED_KICKSTAND_NOT_OUT, 5
      value :PRECONDITION_FAILED_SCOOTER_NOT_LOCKED, 6
    end
  end
end

module Protos
  module Unu
    module V1
      ScooterConfig = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("protos.unu.v1.ScooterConfig").msgclass
      CommandRequest = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("protos.unu.v1.CommandRequest").msgclass
      CommandAcknowledgement = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("protos.unu.v1.CommandAcknowledgement").msgclass
      Command = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("protos.unu.v1.Command").enummodule
      CommandStatus = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("protos.unu.v1.CommandStatus").enummodule
      PreconditionFailed = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("protos.unu.v1.PreconditionFailed").enummodule
    end
  end
end
