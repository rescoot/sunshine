# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: unu/v1/snapshot.proto

require "google/protobuf"

require "google/protobuf/timestamp_pb"
Google::Protobuf::DescriptorPool.generated_pool.build do
  add_file("unu/v1/snapshot.proto", syntax: :proto3) do
    add_message "protos.unu.v1.SnapshotCommandRequest" do
      optional :command, :enum, 1, "protos.unu.v1.SnapshotCommand"
    end
    add_message "protos.unu.v1.SnapshotCommandResponse" do
      optional :command, :enum, 1, "protos.unu.v1.SnapshotCommand"
      optional :result, :string, 2
      optional :ts, :message, 3, "google.protobuf.Timestamp"
      optional :return_code, :int32, 4
    end
    add_enum "protos.unu.v1.SnapshotCommand" do
      value :SNAPSHOT_COMMAND_UNSPECIFIED, 0
      value :SNAPSHOT_COMMAND_GET_REDIS_STATE, 1
      value :SNAPSHOT_COMMAND_GET_PS_STATE, 2
      value :SNAPSHOT_COMMAND_GET_SYSTEMD_STATE, 3
      value :SNAPSHOT_COMMAND_ENABLE_LOGGING, 4
      value :SNAPSHOT_COMMAND_DISABLE_LOGGING, 5
      value :SNAPSHOT_COMMAND_GET_SYSTEMD_RESTARTS, 6
      value :SNAPSHOT_COMMAND_HARD_RESET_OTA_MDB, 7
      value :SNAPSHOT_COMMAND_HARD_RESET_OTA_DBC, 8
      value :SNAPSHOT_COMMAND_FETCH_UPDATE, 9
      value :SNAPSHOT_COMMAND_ROTATE_CREDENTIALS, 10
      value :SNAPSHOT_COMMAND_RESTART_OTA_SERVICE, 11
      value :SNAPSHOT_COMMAND_OTA_MIGRATE_TO_HERE, 12
      value :SNAPSHOT_COMMAND_OTA_MIGRATE_TO_FOUNDRIES, 13
      value :SNAPSHOT_COMMAND_OTA_PULL_CONFIG, 14
      value :SNAPSHOT_COMMAND_REFRESH_STATE, 15
    end
  end
end

module Protos
  module Unu
    module V1
      SnapshotCommandRequest = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("protos.unu.v1.SnapshotCommandRequest").msgclass
      SnapshotCommandResponse = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("protos.unu.v1.SnapshotCommandResponse").msgclass
      SnapshotCommand = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("protos.unu.v1.SnapshotCommand").enummodule
    end
  end
end
