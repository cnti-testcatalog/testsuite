require "./../spec_helper"
require "colorize"

describe "Platform" do
  before_all do
    # LOGGING.debug `pwd` 
    # LOGGING.debug `echo $KUBECONFIG`
    `./cnf-conformance samples_cleanup`
    $?.success?.should be_true
    `./cnf-conformance setup`
    $?.success?.should be_true
  end

  after_all do
    # cleanup cluster api stuff
    `kubectl delete -f capd.yaml`
    `clusterctl delete  --all`
    `rm -r cluster-api`
  end

  it "'clusterapi_enabled' test works" do
    `./cnf-conformance cleanup`
    `./tools/cluster-api-dev-setup/spec_mock_cluster_api_spec_commands.sh`
    $?.success?.should be_true
    response_s = `./cnf-conformance clusterapi_enabled poc`
    LOGGING.info response_s
    puts response_s
    (/Cluster API is enabled/ =~ response_s).should_not be_nil
  end
end

