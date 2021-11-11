require "./cnf_manager.cr"

module CNFManager
  module CNFAirGap
    #  LOGGING.info ./cnf-testsuite cnf_setup cnf-config=example-cnfs/coredns/cnf-testsuite.yml airgapped output-file=./tmp/airgapped.tar.gz
    #  LOGGING.info ./cnf-testsuite cnf_setup cnf-config=example-cnfs/coredns/cnf-testsuite.yml output-file=./tmp/airgapped.tar.gz
    #  LOGGING.info ./cnf-testsuite cnf_setup cnf-config=example-cnfs/coredns/cnf-testsuite.yml airgapped=./tmp/airgapped.tar.gz
    def self.generate_cnf_setup(config_file : String, output_file, cli_args)
      Log.info { "generate_cnf_setup cnf_config_file: #{config_file}" }
      FileUtils.mkdir_p("#{TarClient::TAR_IMAGES_DIR}")
      # todo create a way to call setup code for directories (cnf manager code)
      config = CNFManager.parsed_config_file(config_file)
      sandbox_config = CNFManager::Config.parse_config_yml(CNFManager.ensure_cnf_testsuite_yml_path(config_file), airgapped: false, generate_tar_mode: true) 
      Log.info { "generate sandbox args: sandbox_config: #{sandbox_config}, cli_args: #{cli_args}" }
      CNFManager.sandbox_setup(sandbox_config, cli_args)
      install_method = CNFManager.cnf_installation_method(config)
      Log.info { "generate_cnf_setup images_from_config_src" }

      Log.info { "Download CRI Tools" }
      AirGap.download_cri_tools

      Log.info { "Add CRI Tools to Airgapped Tar: #{output_file}" }
      TarClient.append(output_file, TarClient::TAR_TMP_BASE, "bin/crictl-#{AirGap::CRI_VERSION}-linux-amd64.tar.gz")
      TarClient.append(output_file, TarClient::TAR_TMP_BASE, "bin/containerd-#{AirGap::CTR_VERSION}-linux-amd64.tar.gz")

      images = CNFManager::GenerateConfig.images_from_config_src(install_method[1], generate_tar_mode: true) 

      # todo function that takes sandbox containers and extracts images (config images)
      container_names = sandbox_config.cnf_config[:container_names]
      #todo get image name (org name and image name) from config src

      if container_names
        config_images = [] of NamedTuple(image_name: String, tag: String)
        container_names.map do |c|
          Log.info { "container_names c: #{c}" }
          # todo get image name for container name
          image = images.find{|x| x[:container_name]==c["name"]}
          if image
            config_images << {image_name: image[:image_name], tag: c["rolling_update_test_tag"]}
            config_images << {image_name: image[:image_name], tag: c["rolling_downgrade_test_tag"]}
            config_images << {image_name: image[:image_name], tag: c["rolling_version_change_test_tag"]}
            config_images << {image_name: image[:image_name], tag: c["rollback_from_tag"]}
          end
        end
      else
        config_images = [] of NamedTuple(image_name: String, tag: String)
      end
      Log.info { "config_images: #{config_images}" }

      # todo function that accepts image names and tars them
      images = images + config_images
      images.map  do |i|
        input_file = "#{TarClient::TAR_IMAGES_DIR}/#{i[:image_name].split("/")[-1]}_#{i[:tag]}.tar"
        Log.info { "input_file: #{input_file}" }
        image = "#{i[:image_name]}:#{i[:tag]}"
        DockerClient.pull(image)
        DockerClient.save(image, input_file)
        TarClient.append(output_file, "/tmp", "images/" + input_file.split("/")[-1])
        Log.info { "#{output_file} in generate_cnf_setup complete" }
      end
      # todo hardcode install method for helm charts until helm directories / manifest 
      #  directories are supported
      case install_method[0]
      when Helm::InstallMethod::HelmChart
        Log.debug { "helm_chart : #{install_method[1]}" }
        AirGap.tar_helm_repo(install_method[1], output_file)
        Log.info { "generate_cnf_setup tar_helm_repo complete" }
        # when Helm::InstallMethod::ManifestDirectory
        #   LOGGING.debug "manifest_directory : #{install_method[1]}"
        #   template_files = Find.find(directory, "*.yaml*", "100")
        #   template_files.map{|x| AirGap.image_pull_policy(x)}
      end
    end

    #./cnf-testsuite airgapped -o ~/airgapped.tar.gz
    #./cnf-testsuite offline -o ~/airgapped.tar.gz
    #./cnf-testsuite offline -o ~/mydir/airgapped.tar.gz
    def self.generate(output_file : String = "./airgapped.tar.gz")
      Log.info { "cnf_manager generate" }
      FileUtils.rm_rf(output_file)
      FileUtils.mkdir_p("#{AirGap::TAR_BOOTSTRAP_IMAGES_DIR}")
      FileUtils.mkdir_p("#{AirGap::TAR_BINARY_DIR}")

      # todo put all of these setup elements into a configuration file.
      # todo get this images from helm charts.

      [{input_file: "#{AirGap::TAR_BOOTSTRAP_IMAGES_DIR}/kubectl.tar", 
        image: "bitnami/kubectl:latest"},
      {input_file: "#{AirGap::TAR_BOOTSTRAP_IMAGES_DIR}/chaos-mesh.tar", 
       image: "pingcap/chaos-mesh:v1.2.1"},
      {input_file: "#{AirGap::TAR_BOOTSTRAP_IMAGES_DIR}/chaos-daemon.tar", 
       image: "pingcap/chaos-daemon:v1.2.1"},
      {input_file: "#{AirGap::TAR_BOOTSTRAP_IMAGES_DIR}/chaos-dashboard.tar", 
       image: "pingcap/chaos-dashboard:v1.2.1"},
      {input_file: "#{AirGap::TAR_BOOTSTRAP_IMAGES_DIR}/chaos-kernel.tar", 
       image: "pingcap/chaos-kernel:v1.2.1"},
      {input_file: "#{AirGap::TAR_BOOTSTRAP_IMAGES_DIR}/pingcap-coredns.tar", 
       image: "pingcap/coredns:v0.2.0"},
      {input_file: "#{AirGap::TAR_BOOTSTRAP_IMAGES_DIR}/sonobuoy.tar", 
       image: "docker.io/sonobuoy/sonobuoy:v0.19.0"},
      {input_file: "#{AirGap::TAR_BOOTSTRAP_IMAGES_DIR}/sonobuoy-logs.tar", 
       image: "docker.io/sonobuoy/systemd-logs:v0.3"},
      {input_file: "#{AirGap::TAR_BOOTSTRAP_IMAGES_DIR}/litmus-operator.tar", 
       image: "litmuschaos/chaos-operator:#{LitmusManager::Version}"},
      {input_file: "#{AirGap::TAR_BOOTSTRAP_IMAGES_DIR}/litmus-runner.tar", 
       image: "litmuschaos/chaos-runner:#{LitmusManager::Version}"},
      {input_file: "#{AirGap::TAR_BOOTSTRAP_IMAGES_DIR}/go-runner.tar", 
       image: "litmuschaos/go-runner:#{LitmusManager::Version}"},
      {input_file: "#{AirGap::TAR_BOOTSTRAP_IMAGES_DIR}/kind-node.tar", 
       image: "kindest/node:v1.21.1"},
      {input_file: "#{AirGap::TAR_BOOTSTRAP_IMAGES_DIR}/gatekeeper.tar", 
       image: "openpolicyagent/gatekeeper:v3.6.0"},
      {input_file: "#{AirGap::TAR_BOOTSTRAP_IMAGES_DIR}/gatekeeper-crds.tar", 
       image: "openpolicyagent/gatekeeper-crds:v3.6.0"},
      {input_file: "#{AirGap::TAR_BOOTSTRAP_IMAGES_DIR}/tigera-operator.tar", 
       image: "quay.io/tigera/operator:v1.20.4"},
      {input_file: "#{AirGap::TAR_BOOTSTRAP_IMAGES_DIR}/calico-controller.tar", 
       image: "calico/kube-controllers:v3.20.2"},
      {input_file: "#{AirGap::TAR_BOOTSTRAP_IMAGES_DIR}/calico-flexvol.tar", 
       image: "calico/pod2daemon-flexvol:v3.20.2"},
      {input_file: "#{AirGap::TAR_BOOTSTRAP_IMAGES_DIR}/calico-cni.tar", 
       image: "calico/cni:v3.20.2"},
      {input_file: "#{AirGap::TAR_BOOTSTRAP_IMAGES_DIR}/calico-node.tar", 
       image: "calico/node:v3.20.2"},
      {input_file: "#{AirGap::TAR_BOOTSTRAP_IMAGES_DIR}/calico-typha.tar", 
       image: "calico/typha:v3.20.2"},
      {input_file: "#{AirGap::TAR_BOOTSTRAP_IMAGES_DIR}/cilium.tar", 
       image: "cilium/cilium:v1.10.5"},
      {input_file: "#{AirGap::TAR_BOOTSTRAP_IMAGES_DIR}/cilium-operator.tar", 
       image: "cilium/operator-generic:v1.10.5"},
      {input_file: "#{AirGap::TAR_BOOTSTRAP_IMAGES_DIR}/prometheus.tar", 
       image: "prom/prometheus:v2.18.1"}].map do |x|
        DockerClient.pull(x[:image])
        DockerClient.save(x[:image], x[:input_file])
        TarClient.append(output_file, TarClient::TAR_TMP_BASE, "bootstrap_images/" + x[:input_file].split("/")[-1])
      end
      # todo keep crictl and containerd tar files, move to the rest to cnf-test-suite specific bootstrap
      AirGap.tar_manifest("https://litmuschaos.github.io/litmus/litmus-operator-v#{LitmusManager::Version}.yaml", output_file)
      AirGap.tar_manifest("https://raw.githubusercontent.com/litmuschaos/chaos-operator/master/deploy/chaos_crds.yaml", output_file)
      AirGap.tar_manifest("https://hub.litmuschaos.io/api/chaos/#{LitmusManager::Version}?file=charts/generic/pod-network-latency/experiment.yaml", output_file, prefix: "lat-")
      AirGap.tar_manifest("https://hub.litmuschaos.io/api/chaos/#{LitmusManager::Version}?file=charts/generic/pod-network-latency/rbac.yaml", output_file, prefix: "lat-")
      AirGap.tar_manifest("https://hub.litmuschaos.io/api/chaos/#{LitmusManager::Version}?file=charts/generic/pod-network-corruption/experiment.yaml", output_file, prefix: "corr-")
      AirGap.tar_manifest("https://hub.litmuschaos.io/api/chaos/#{LitmusManager::Version}?file=charts/generic/pod-network-corruption/rbac.yaml", output_file, prefix:  "corr-")
      AirGap.tar_manifest("https://hub.litmuschaos.io/api/chaos/#{LitmusManager::Version}?file=charts/generic/pod-network-duplication/experiment.yaml", output_file, prefix: "dup-")
      AirGap.tar_manifest("https://hub.litmuschaos.io/api/chaos/#{LitmusManager::Version}?file=charts/generic/pod-network-duplication/rbac.yaml", output_file, prefix:  "dup-")
      AirGap.tar_manifest("https://hub.litmuschaos.io/api/chaos/#{LitmusManager::Version}?file=charts/generic/pod-delete/experiment.yaml", output_file, prefix: "pod-delete-")
      AirGap.tar_manifest("https://hub.litmuschaos.io/api/chaos/#{LitmusManager::Version}?file=charts/generic/pod-delete/rbac.yaml", output_file, prefix:  "pod-delete-")
      AirGap.tar_manifest("https://hub.litmuschaos.io/api/chaos/#{LitmusManager::Version}?file=charts/generic/pod-memory-hog/experiment.yaml", output_file, prefix: "pod-memory-hog-")
      AirGap.tar_manifest("https://hub.litmuschaos.io/api/chaos/#{LitmusManager::Version}?file=charts/generic/pod-memory-hog/rbac.yaml", output_file, prefix:  "pod-memory-hog-")
      AirGap.tar_manifest("https://hub.litmuschaos.io/api/chaos/#{LitmusManager::Version}?file=charts/generic/pod-io-stress/experiment.yaml", output_file, prefix: "pod-io-stress-")
      AirGap.tar_manifest("https://hub.litmuschaos.io/api/chaos/#{LitmusManager::Version}?file=charts/generic/pod-io-stress/rbac.yaml", output_file, prefix:  "pod-io-stress-")
      AirGap.tar_manifest("https://hub.litmuschaos.io/api/chaos/#{LitmusManager::Version}?file=charts/generic/disk-fill/experiment.yaml", output_file, prefix:  "disk-fill-")
      AirGap.tar_manifest("https://hub.litmuschaos.io/api/chaos/#{LitmusManager::Version}?file=charts/generic/disk-fill/rbac.yaml", output_file, prefix:  "disk-fill-")
      url = "https://github.com/vmware-tanzu/sonobuoy/releases/download/v#{SONOBUOY_K8S_VERSION}/sonobuoy_#{SONOBUOY_K8S_VERSION}_#{SONOBUOY_OS}_amd64.tar.gz"
      TarClient.tar_file_by_url(url, output_file, "sonobuoy.tar.gz")
      url = "https://github.com/armosec/kubescape/releases/download/v#{KUBESCAPE_VERSION}/kubescape-ubuntu-latest"
      TarClient.tar_file_by_url(url, output_file, "kubescape-ubuntu-latest")
      url = "https://github.com/kubernetes-sigs/kind/releases/download/v#{KIND_VERSION}/kind-linux-amd64"
      TarClient.tar_file_by_url(url, output_file, "kind")
      download_path = "download/" 
      FileUtils.rm_rf("#{TarClient::TAR_TMP_BASE}/#{download_path}")
      FileUtils.mkdir_p("#{TarClient::TAR_TMP_BASE}/" + download_path)
      `./tools/kubescape/kubescape download framework nsa --output #{TarClient::TAR_DOWNLOAD_DIR}/nsa.json`
      TarClient.append(output_file, TarClient::TAR_TMP_BASE, "#{download_path}/nsa.json")
      Helm.helm_repo_add("chaos-mesh", "https://charts.chaos-mesh.org")
      # todo create helm chart configuration yaml that includes all chart elements for specs
      AirGap.tar_helm_repo("chaos-mesh/chaos-mesh --version 0.5.1", output_file)
      Helm.helm_repo_add("gatekeeper","https://open-policy-agent.github.io/gatekeeper/charts")
      
      # Calico Helm  Relase Can't be Pinned, Download Directly
      # Helm.helm_repo_add("projectcalico","https://docs.projectcalico.org/charts")
      # AirGap.tar_helm_repo("projectcalico/tigera-operator --version v3.20.2", output_file)

      tar_dir = AirGap.helm_tar_dir("projectcalico/tigera-operator")
      info = AirGap.tar_info_by_config_src("projectcalico/tigera-operator")
      tar_name = info[:tar_name]
      Helm.fetch("https://github.com/projectcalico/calico/releases/download/v3.20.2/tigera-operator-v3.20.2-1.tgz -d #{tar_dir}")
      Log.info { "TarDir: #{tar_dir}, TarName: #{tar_name}" }
      TarClient.append(output_file, TarClient::TAR_TMP_BASE, "#{tar_dir}/#{tar_name}")

      Helm.helm_repo_add("cilium","https://helm.cilium.io/")
      AirGap.tar_helm_repo("cilium/cilium --version 1.10.5", output_file)
      AirGap.tar_helm_repo("gatekeeper/gatekeeper --version 3.6.0", output_file)
      AirGap.generate(output_file, append=true)
    end
  end
end
