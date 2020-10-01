require "./../spec_helper"
require "colorize"

describe "Platform" do
  before_all do
    `./cnf-conformance setup`
    $?.success?.should be_true
  end

  after_all do
    # cleanup cluster api stuff
    `kubectl delete -f cluster-api/capd.yaml`
    `clusterctl delete  --all`
    `rm -rf cluster-api`
  end

  it "'clusterapi_enabled' test works" do
    `./tools/cluster-api-dev-setup/spec_mock_cluster_api_spec_commands.sh`
    $?.success?.should be_true
    response_s = `./cnf-conformance clusterapi_enabled poc`
    LOGGING.info response_s
    puts response_s
    (/Cluster API is enabled/ =~ response_s).should_not be_nil
  end
end

