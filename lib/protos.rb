$LOAD_PATH.unshift Rails.root.join("lib/protos")

require_relative "protos/unu/v1/command_pb.rb"
require_relative "protos/unu/v1/scooter_state_pb.rb"
require_relative "protos/unu/v1/scooter_event_pb.rb"
require_relative "protos/unu/v1/snapshot_pb.rb"
