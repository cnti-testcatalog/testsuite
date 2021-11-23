## Generated from google/protobuf/timestamp.proto for google.protobuf
require "protobuf"

module Google
  module Protobuf
    
    struct Timestamp
      include ::Protobuf::Message
      
      contract_of "proto3" do
        optional :seconds, :int64, 1
        optional :nanos, :int32, 2
      end
    end
    end
  end
