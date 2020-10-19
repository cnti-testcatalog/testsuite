require "./../spec_helper"
require "colorize"
require "file_utils"

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
    # `./tools/cluster-api-dev-setup/spec_mock_cluster_api_spec_commands.sh`
    current_dir = FileUtils.pwd 
    unless Dir.exists?("#{current_dir}/#{TOOLS_DIR}/cluster-api")
      `git clone https://github.com/kubernetes-sigs/cluster-api --depth 1 --branch v0.3.9 "#{current_dir}/#{TOOLS_DIR}/cluster-api"`
    end
    FileUtils.cd("#{current_dir}/#{TOOLS_DIR}/cluster-api")
    File.write("clusterctl-settings.json",
<<-EOF
{
  "providers": ["cluster-api","bootstrap-kubeadm","control-plane-kubeadm", "infrastructure-docker"]
}
EOF
)
    `./cmd/clusterctl/hack/local-overrides.py`
    File.write("clusterctl.yaml", 
<<-EOF
providers:
  - name: docker
    url: #{Path["~"].expand(home: true)}/.cluster-api/overrides/infrastructure-docker/v0.3.0/infrastructure-components.yaml
    type: InfrastructureProvider
EOF
)
    puts "init"
    LOGGING.info `clusterctl init --core cluster-api:v0.3.0  --bootstrap kubeadm:v0.3.0    --control-plane kubeadm:v0.3.0    --infrastructure docker:v0.3.0 --config #{FileUtils.pwd}/clusterctl-settings.json`
    # $?.success?.should be_true
    response_s = `./cnf-conformance clusterapi_enabled poc`
    LOGGING.info response_s
    puts response_s
    # (/Cluster API is enabled/ =~ response_s).should_not be_nil
  end
end

