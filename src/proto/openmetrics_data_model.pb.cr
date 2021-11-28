## Generated from openmetrics_data_model.proto for openmetrics
require "protobuf"

require "./timestamp.pb.cr"

module Openmetrics
  enum MetricType
    UNKNOWN = 0
    GAUGE = 1
    COUNTER = 2
    STATESET = 3
    INFO = 4
    HISTOGRAM = 5
    GAUGEHISTOGRAM = 6
    SUMMARY = 7
  end
  
  struct MetricSet
    include ::Protobuf::Message
    
    contract_of "proto3" do
      repeated :metric_families, MetricFamily, 1
    end
  end
  
  struct MetricFamily
    include ::Protobuf::Message
    
    contract_of "proto3" do
      optional :name, :string, 1
      optional :type, MetricType, 2
      optional :unit, :string, 3
      optional :help, :string, 4
      repeated :metrics, Metric, 5
    end
  end
  
  struct Metric
    include ::Protobuf::Message
    
    contract_of "proto3" do
      repeated :labels, Label, 1
      repeated :metric_points, MetricPoint, 2
    end
  end
  
  struct Label
    include ::Protobuf::Message
    
    contract_of "proto3" do
      optional :name, :string, 1
      optional :value, :string, 2
    end
  end
  
  struct MetricPoint
    include ::Protobuf::Message
    
    contract_of "proto3" do
      optional :unknown_value, UnknownValue, 1
      optional :gauge_value, GaugeValue, 2
      optional :counter_value, CounterValue, 3
      optional :histogram_value, HistogramValue, 4
      optional :state_set_value, StateSetValue, 5
      optional :info_value, InfoValue, 6
      optional :summary_value, SummaryValue, 7
      optional :timestamp, Google::Protobuf::Timestamp, 8
    end
  end
  
  struct UnknownValue
    include ::Protobuf::Message
    
    contract_of "proto3" do
      optional :double_value, :double, 1
      optional :int_value, :int64, 2
    end
  end
  
  struct GaugeValue
    include ::Protobuf::Message
    
    contract_of "proto3" do
      optional :double_value, :double, 1
      optional :int_value, :int64, 2
    end
  end
  
  struct CounterValue
    include ::Protobuf::Message
    
    contract_of "proto3" do
      optional :double_value, :double, 1
      optional :int_value, :uint64, 2
      optional :created, Google::Protobuf::Timestamp, 3
      optional :exemplar, Exemplar, 4
    end
  end
  
  struct HistogramValue
    include ::Protobuf::Message
    
    struct Bucket
      include ::Protobuf::Message
      
      contract_of "proto3" do
        optional :count, :uint64, 1
        optional :upper_bound, :double, 2
        optional :exemplar, Exemplar, 3
      end
    end
    
    contract_of "proto3" do
      optional :double_value, :double, 1
      optional :int_value, :int64, 2
      optional :count, :uint64, 3
      optional :created, Google::Protobuf::Timestamp, 4
      repeated :buckets, HistogramValue::Bucket, 5
    end
  end
  
  struct Exemplar
    include ::Protobuf::Message
    
    contract_of "proto3" do
      optional :value, :double, 1
      optional :timestamp, Google::Protobuf::Timestamp, 2
      repeated :label, Label, 3
    end
  end
  
  struct StateSetValue
    include ::Protobuf::Message
    
    struct State
      include ::Protobuf::Message
      
      contract_of "proto3" do
        optional :enabled, :bool, 1
        optional :name, :string, 2
      end
    end
    
    contract_of "proto3" do
      repeated :states, StateSetValue::State, 1
    end
  end
  
  struct InfoValue
    include ::Protobuf::Message
    
    contract_of "proto3" do
      repeated :info, Label, 1
    end
  end
  
  struct SummaryValue
    include ::Protobuf::Message
    
    struct Quantile
      include ::Protobuf::Message
      
      contract_of "proto3" do
        optional :quantile, :double, 1
        optional :value, :double, 2
      end
    end
    
    contract_of "proto3" do
      optional :double_value, :double, 1
      optional :int_value, :int64, 2
      optional :count, :uint64, 3
      optional :created, Google::Protobuf::Timestamp, 4
      repeated :quantile, SummaryValue::Quantile, 5
    end
  end
  end
