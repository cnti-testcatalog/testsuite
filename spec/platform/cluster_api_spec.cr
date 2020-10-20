require "./../spec_helper"
require "colorize"
require "file_utils"
require "./../../src/tasks/utils/utils.cr"

describe "Platform" do
  before_all do
    `./cnf-conformance setup`
    $?.success?.should be_true
  end

  after_all do
    # cleanup cluster api stuff
    current_dir = FileUtils.pwd 
    cluster_api_dir = "#{current_dir}/#{TOOLS_DIR}/cluster-api"
    `kubectl delete -f #{cluster_api_dir}/capd.yaml`
    `clusterctl delete --all --include-crd --include-namespace --config #{cluster_api_dir}/clusterctl.yaml`
#    `rm -rf #{current_dir}/#{TOOLS_DIR}/cluster-api`
  end

  it "'clusterapi_enabled' test works" do
    begin
      # `./tools/cluster-api-dev-setup/spec_mock_cluster_api_spec_commands.sh`
      current_dir = FileUtils.pwd 
      cluster_api_dir =  "#{current_dir}/#{TOOLS_DIR}/cluster-api";
      unless Dir.exists?(cluster_api_dir)
        `git clone https://github.com/kubernetes-sigs/cluster-api --depth 1 --branch v0.3.9 "#{cluster_api_dir}"`
      end
      FileUtils.cd(cluster_api_dir)
      File.write("clusterctl-settings.json",
<<-EOF
{"providers": ["cluster-api","bootstrap-kubeadm","control-plane-kubeadm", "infrastructure-docker"]}
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


      test = `clusterctl init --core cluster-api:v0.3.0  --bootstrap kubeadm:v0.3.0    --control-plane kubeadm:v0.3.0    --infrastructure docker:v0.3.0 --config #{FileUtils.pwd}/clusterctl.yaml`
      puts test

      $?.success?.should be_true


      ## TODO: wait here for crds to be created if needed
create_capd_response =`
CNI_RESOURCES="$(cat test/e2e/data/cni/kindnet/kindnet.yaml)" \
DOCKER_POD_CIDRS="192.168.0.0/16" \
DOCKER_SERVICE_CIDRS="172.17.0.0/16" \
DOCKER_SERVICE_DOMAIN="cluster.local" \
clusterctl config cluster capd --kubernetes-version v1.17.5 \
--from ./test/e2e/data/infrastructure-docker/cluster-template.yaml \
--target-namespace default \
--control-plane-machine-count=1 \
--worker-machine-count=2
`

      LOGGING.info create_capd_response 
      CNFManager.wait_for_install(deployment_name: "cert-manager", namespace: "cert-manager")

      CNFManager.wait_for_install(deployment_name: "cert-manager-cainjector", namespace: "cert-manager")

      CNFManager.wait_for_install(deployment_name: "cert-manager-webhook", namespace: "cert-manager")

      File.write("capd.yaml", create_capd_response)

      # CNFManager.wait_for_crd("providers.clusterctl.cluster.x-k8s.io")
      LOGGING.info `kubectl apply -f capd.yaml`

      ensure
      FileUtils.cd("#{current_dir}")
      response_s = `./cnf-conformance clusterapi_enabled poc`
      LOGGING.info response_s
      (/Cluster API is enabled/ =~ response_s).should_not be_nil
    end
  end
end

