require "sam"
require "file_utils"
require "colorize"
require "totem"
require "http/client" 
require "halite" 
require "./utils/utils.cr"

desc "Install Cluster API for Kind"
task "cluster_api_setup" do |_, args|
      current_dir = FileUtils.pwd 
      cluster_api_dir =  "#{current_dir}/#{TOOLS_DIR}/cluster-api";

      # `curl -L https://github.com/kubernetes-sigs/cluster-api/releases/download/v0.3.10/clusterctl-linux-amd64 -o clusterctl`
      Halite.follow.get("https://github.com/kubernetes-sigs/cluster-api/releases/download/v0.3.10/clusterctl-linux-amd64") do |response| 
        LOGGING.info "clusterctl response: #{response}"
        File.write("clusterctl", response.body_io)
      end 
      LOGGING.info `sudo chmod +x ./clusterctl`
      LOGGING.info `sudo mv ./clusterctl /usr/local/bin/clusterctl`
      
      unless Dir.exists?(cluster_api_dir)
        LOGGING.info `git clone https://github.com/kubernetes-sigs/cluster-api --depth 1 --branch v0.3.10 "#{cluster_api_dir}"`
      end
      FileUtils.cd(cluster_api_dir)
      File.write("clusterctl-settings.json",
<<-EOF
{"providers": ["cluster-api","bootstrap-kubeadm","control-plane-kubeadm", "infrastructure-docker"]}
EOF
  )
      `./cmd/clusterctl/hack/create-local-repository.py`
      File.write("clusterctl.yaml", 
<<-EOF
providers:
  - name: docker
    url: #{Path["~"].expand(home: true)}/.cluster-api/dev-repository/infrastructure-docker/v0.3.8/infrastructure-components.yaml
    type: InfrastructureProvider
EOF
  )


      test = `clusterctl init --core cluster-api:v0.3.8  --bootstrap kubeadm:v0.3.8    --control-plane kubeadm:v0.3.8    --infrastructure docker:v0.3.8 --config #{FileUtils.pwd}/clusterctl.yaml`
      LOGGING.info test

      ## TODO: wait here for crds to be created if needed
create_capd_response =`
CNI_RESOURCES="$(cat test/e2e/data/cni/kindnet/kindnet.yaml)" \
DOCKER_POD_CIDRS="192.168.0.0/16" \
DOCKER_SERVICE_CIDRS="172.17.0.0/16" \
DOCKER_SERVICE_DOMAIN="cluster.local" \
clusterctl config cluster capd --kubernetes-version v1.17.5 \
--from https://github.com/kubernetes-sigs/cluster-api/blob/v0.3.9/test/e2e/data/infrastructure-docker/cluster-template.yaml \
--target-namespace default \
--control-plane-machine-count=1 \
--worker-machine-count=2
`

      LOGGING.info create_capd_response 

      File.write("capd.yaml", create_capd_response)

      KubectlClient::Get.wait_for_install_by_apply("capd.yaml")

      LOGGING.info `kubectl apply -f capd.yaml`
      LOGGING.info "cluster api setup complete"
end

desc "Cleanup Cluster API"
task "cluster_api_cleanup" do |_, args|
  current_dir = FileUtils.pwd 
  cluster_api_dir = "#{current_dir}/#{TOOLS_DIR}/cluster-api"
  `kubectl delete -f #{cluster_api_dir}/capd.yaml`
  `clusterctl delete --all --include-crd --include-namespace --config #{cluster_api_dir}/clusterctl.yaml`
  `rm -rf #{current_dir}/#{TOOLS_DIR}/cluster-api`

end

