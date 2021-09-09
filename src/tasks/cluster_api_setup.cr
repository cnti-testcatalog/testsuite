require "sam"
require "file_utils"
require "colorize"
require "totem"
require "http/client"
require "halite"
require "./utils/utils.cr"
require "json"
require "yaml"

desc "Install Cluster API for Kind"
task "cluster_api_setup" do |_, args|
  current_dir = FileUtils.pwd
  cluster_api_dir = "#{current_dir}/#{TOOLS_DIR}/cluster-api"

  # curl -L https://github.com/kubernetes-sigs/cluster-api/releases/download/v0.3.10/clusterctl-linux-amd64 -o clusterctl
  Halite.follow.get("https://github.com/kubernetes-sigs/cluster-api/releases/download/v0.3.10/clusterctl-linux-amd64") do |response|
    Log.info { "clusterctl response: #{response}" }
    File.write("clusterctl", response.body_io)
  end

  Process.run(
    "sudo chmod +x ./clusterctl",
    shell: true,
    output: stdout = IO::Memory.new,
    error: stderr = IO::Memory.new
  )
  Process.run(
    "sudo mv ./clusterctl /usr/local/bin/clusterctl",
    shell: true,
    output: stdout = IO::Memory.new,
    error: stderr = IO::Memory.new
  )

  unless Dir.exists?(cluster_api_dir)
    cmd = "git clone https://github.com/kubernetes-sigs/cluster-api --depth 1 --branch v0.3.10 #{cluster_api_dir}"
    stdout = IO::Memory.new
    Process.run(cmd, shell: true, output: stdout, error: stdout)
    Log.for("git clone kubernetes-sigs/cluster-api").info { stdout.to_s }
  end
  FileUtils.cd(cluster_api_dir)
  clusterctl_settings = {
    "providers": [
      "cluster-api",
      "bootstrap-kubeadm",
      "control-plane-kubeadm",
      "infrastructure-docker"
    ]
  }.to_json
  File.write("clusterctl-settings.json", clusterctl_settings)

  Process.run("./cmd/clusterctl/hack/create-local-repository.py", shell: true, output: stdout = IO::Memory.new, error: stderr = IO::Memory.new)

  clusterctl_config = {
    providers: [
      {
        name: "docker",
        url: "#{Path["~"].expand(home: true)}/.cluster-api/dev-repository/infrastructure-docker/v0.3.8/infrastructure-components.yaml",
        type: "InfrastructureProvider"
      }
    ]
  }.to_yaml
  File.write("clusterctl.yaml", clusterctl_config)

  cluster_init_cmd = "clusterctl init --core cluster-api:v0.3.8  --bootstrap kubeadm:v0.3.8 --control-plane kubeadm:v0.3.8 --infrastructure docker:v0.3.8 --config #{FileUtils.pwd}/clusterctl.yaml"
  stdout = IO::Memory.new
  Process.run(cluster_init_cmd, shell: true, output: stdout, error: stdout)
  Log.info { stdout }

  ## TODO: wait here for crds to be created if needed

  create_capd_cmd = <<-HEREDOC
  CNI_RESOURCES="$(cat test/e2e/data/cni/kindnet/kindnet.yaml)" \
  DOCKER_POD_CIDRS="192.168.0.0/16" \
  DOCKER_SERVICE_CIDRS="172.17.0.0/16" \
  DOCKER_SERVICE_DOMAIN="cluster.local" \
  clusterctl config cluster capd --kubernetes-version v1.17.5 \
  --from https://github.com/kubernetes-sigs/cluster-api/blob/v0.3.9/test/e2e/data/infrastructure-docker/cluster-template.yaml \
  --target-namespace default \
  --control-plane-machine-count=1 \
  --worker-machine-count=2
  HEREDOC

  Process.run(
    create_capd_cmd,
    shell: true,
    output: create_capd_stdout = IO::Memory.new,
    error: create_capd_stderr = IO::Memory.new
  )
  create_capd_resp = create_capd_stdout.to_s

  Log.info { create_capd_resp }
  File.write("capd.yaml", create_capd_resp)
  KubectlClient::Get.wait_for_install_by_apply("capd.yaml")
  KubectlClient::Apply.file("capd.yaml")
  Log.info { "cluster api setup complete" }
end

desc "Cleanup Cluster API"
task "cluster_api_cleanup" do |_, args|
  current_dir = FileUtils.pwd 
  cluster_api_dir = "#{current_dir}/#{TOOLS_DIR}/cluster-api"
  KubectlClient::Delete.file("#{cluster_api_dir}/capd.yaml")

  cmd = "clusterctl delete --all --include-crd --include-namespace --config #{cluster_api_dir}/clusterctl.yaml"
  Process.run(cmd, shell: true, output: stdout = IO::Memory.new, error: stderr = IO::Memory.new)

  FileUtils.rm_rf("#{current_dir}/#{TOOLS_DIR}/cluster-api")
end
