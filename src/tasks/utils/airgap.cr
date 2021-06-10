# coding: utf-8
require "totem"
require "colorize"
require "crinja"
require "./tar.cr"
require "./docker_client.cr"
require "./kubectl_client.cr"
require "./airgap_utils.cr"

module AirGap
  CRI_VERSION="v1.17.0"
  CTR_VERSION="1.5.0"

  #TODO make chainable predicates that allow for bootstraping calls
  # schedulable_nodes() : nodes_json
  #  -> pods_by_node(nodes_json) : pods_json
  #  -> pods_by_label(pods_json, "name=cri-tools") : pods_json
  #  -> cp(pods_json, tarred_image) : pods_json
  #  -> exec(pods_json, command) : pods_json

  #TODO Kubectl::Pods.pods_by_node(nodes_json) : pods_json
  #TODO Kubectl::Pods.pods_by_label(pods_json, "name=cri-tools")
  #TODO Kubectl::Pods.cp(pods_json, tarred_image)
  #TODO Kubectl::Pods.exec(pods_json, command)

  #TODO generate a helm tarball for a helm chart install
  #TODO generate a tarball for a helm directory
  #TODO generate a tarball for a manifest directory
  #TODO append the tarballs to the airgapped tarball (or another tarball)
  #  LOGGING.info ./cnf-testsuite cnf_setup cnf-config=example-cnfs/coredns/cnf-testsuite.yml airgapped output-file=./tmp/airgapped.tar.gz
  #  LOGGING.info ./cnf-testsuite cnf_setup cnf-config=example-cnfs/coredns/cnf-testsuite.yml output-file=./tmp/airgapped.tar.gz
  #  LOGGING.info ./cnf-testsuite cnf_setup cnf-config=example-cnfs/coredns/cnf-testsuite.yml airgapped=./tmp/airgapped.tar.gz
  def self.generate_cnf_setup(config_file, output_file)
    LOGGING.info "generate_cnf_setup cnf_config_file: #{config_file}"
    FileUtils.mkdir_p("#{TarClient::TAR_IMAGES_DIR}")
    config = CNFManager.parsed_config_file(config_file)
    install_method = CNFManager.cnf_installation_method(config)
    case install_method[0]
    when :helm_chart
      LOGGING.debug "helm_chart : #{install_method[1]}"
      TarClient.tar_helm_repo(install_method[1], output_file)
      #TODO get images from helm chart
      #TODO tarball the images
      images = CNFManager::GenerateConfig.images_from_config_src(install_method[1]) 

      images.map  do |i|
        input_file = "#{TarClient::TAR_IMAGES_DIR}/#{i[:image_name].split("/")[-1]}_#{i[:tag]}.tar"
        LOGGING.info "input_file: #{input_file}"
        image = "#{i[:image_name]}:#{i[:tag]}"
        DockerClient.pull(image)
        DockerClient.save(image, input_file)
        # FileUtils.mkdir_p("#{TarClient::TAR_IMAGES_DIR}/#{Path[input_file].parent}")
        # TarClient.append(output_file, Path[input_file].parent, "/images/" + input_file.split("/")[-1])
        TarClient.append(output_file, "/tmp", "images/" + input_file.split("/")[-1])
      end
      # when :helm_directory
      #   LOGGING.debug "helm_directory install method: #{yml_path}/#{install_method[1]}"
      #   release_name = helm_chart_template_release_name("#{yml_path}/#{install_method[1]}")
      # when :manifest_directory
      #   LOGGING.debug "manifest_directory install method"
      #   release_name = UUID.random.to_s
    else
      raise "Install method should be either helm_chart, helm_directory, or manifest_directory"
    end
  end

  # LOGGING.info ./cnf-testsuite cnf_setup offline=./tmp/cnf.tar.gz cnf-config=example-cnfs/coredns/cnf-testsuite.yml
  # LOGGING.info ./cnf-testsuite cnf_setup input_file=./tmp/cnf.tar.gz cnf-config=example-cnfs/coredns/cnf-testsuite.yml
  def self.cnf_setup
    # TODO Extract to the #{TAR_IMAGES_DIR} directory
    #TODO cache the images into the nodes 
    #TODO check for cnf-testsuite file, error out if doesn't exist
    #TODO use cnf-testsuite file to find out which install method will be used
    #TODO install all helm charts and helm directories using helm directory install method
    #TODO install manifests using install manifest method
  end

  #./cnf-testsuite airgapped -o ~/airgapped.tar.gz
  #./cnf-testsuite offline -o ~/airgapped.tar.gz
  #./cnf-testsuite offline -o ~/mydir/airgapped.tar.gz
  def self.generate(output_file : String = "./airgapped.tar.gz")
    `rm #{output_file}`
    FileUtils.mkdir_p("#{TarClient::TAR_IMAGES_DIR}")
    AirGap.download_cri_tools
    [{input_file: "#{TarClient::TAR_IMAGES_DIR}/kubectl.tar", 
      image: "bitnami/kubectl:latest"},
    {input_file: "#{TarClient::TAR_IMAGES_DIR}/chaos-mesh.tar", 
     image: "pingcap/chaos-mesh:v1.2.1"},
    {input_file: "#{TarClient::TAR_IMAGES_DIR}/chaos-daemon.tar", 
     image: "pingcap/chaos-daemon:v1.2.1"},
    {input_file: "#{TarClient::TAR_IMAGES_DIR}/chaos-dashboard.tar", 
     image: "pingcap/chaos-dashboard:v1.2.1"},
    {input_file: "#{TarClient::TAR_IMAGES_DIR}/chaos-kernel.tar", 
     image: "pingcap/chaos-kernel:v1.2.1"},
    {input_file: "#{TarClient::TAR_IMAGES_DIR}/pingcap-coredns.tar", 
     image: "pingcap/coredns:v0.2.0"},
    {input_file: "#{TarClient::TAR_IMAGES_DIR}/sonobuoy.tar", 
     image: "docker.io/sonobuoy/sonobuoy:v0.19.0"},
    {input_file: "#{TarClient::TAR_IMAGES_DIR}/sonobuoy-logs.tar", 
     image: "docker.io/sonobuoy/systemd-logs:v0.3"},
    {input_file: "#{TarClient::TAR_IMAGES_DIR}/litmus-operator.tar", 
     image: "litmuschaos/chaos-operator:1.13.2"},
    {input_file: "#{TarClient::TAR_IMAGES_DIR}/litmus-runner.tar", 
     image: "litmuschaos/chaos-runner:1.13.2"},
    {input_file: "#{TarClient::TAR_IMAGES_DIR}/prometheus.tar", 
     image: "prom/prometheus:v2.18.1"}].map do |x|
      DockerClient.pull(x[:image])
      DockerClient.save(x[:image], x[:input_file])
      TarClient.append(output_file, TarClient::TAR_TMP_BASE, "images/" + x[:input_file].split("/")[-1])
      # TarClient.append(output_file, Path[x[:input_file]].parent, x[:input_file].split("/")[-1])
    end
    #TODO test if these should be in the /tmp/bin directory
    TarClient.append(output_file, TarClient::TAR_TMP_BASE, "crictl-#{CRI_VERSION}-linux-amd64.tar.gz")
    TarClient.append(output_file, TarClient::TAR_TMP_BASE, "containerd-#{CTR_VERSION}-linux-amd64.tar.gz")
    TarClient.tar_manifest("https://litmuschaos.github.io/litmus/litmus-operator-v1.13.2.yaml", output_file)
    TarClient.tar_manifest("https://hub.litmuschaos.io/api/chaos/1.13.2?file=charts/generic/pod-network-latency/experiment.yaml", output_file)
    TarClient.tar_manifest("https://hub.litmuschaos.io/api/chaos/1.13.2?file=charts/generic/pod-network-latency/rbac.yaml", output_file)
    TarClient.tar_manifest("https://hub.litmuschaos.io/api/chaos/1.13.2?file=charts/generic/disk-fill/experiment.yaml", output_file, "disk-fill-")
    TarClient.tar_manifest("https://hub.litmuschaos.io/api/chaos/1.13.2?file=charts/generic/disk-fill/rbac.yaml", output_file, "disk-fill-")
    url = "https://github.com/vmware-tanzu/sonobuoy/releases/download/v#{SONOBUOY_K8S_VERSION}/sonobuoy_#{SONOBUOY_K8S_VERSION}_#{SONOBUOY_OS}_amd64.tar.gz"
    TarClient.tar_file_by_url(url, output_file, "sonobuoy.tar.gz")
    Helm.helm_repo_add("chaos-mesh", "https://charts.chaos-mesh.org")
    TarClient.tar_helm_repo("chaos-mesh/chaos-mesh --version 0.5.1", output_file)
  end

  #./cnf-testsuite setup --offline=./airgapped.tar.gz
  def self.extract(output_file : String = "./airgapped.tar.gz", output_dir="/tmp")
    TarClient.untar(output_file, output_dir)
  end

  def self.cache_images(tarball_name="./airgapped.tar.gz")
    AirGap.bootstrap_cluster()
    if ENV["CRYSTAL_ENV"]? == "TEST"
      # install_list = [{input_file: "/tmp/image/kubectl.tar"}, 
      #                 {input_file: "/tmp/image/chaos-mesh.tar"}]
      image_files = ["#{TarClient::TAR_IMAGES_DIR}/kubectl.tar", 
                      "#{TarClient::TAR_IMAGES_DIR}/chaos-mesh.tar"]
    else
      #TODO function that loops through all of the tar files that are image files
      tar_image_files = TarClient.find("#{TarClient::TAR_IMAGES_DIR}", "*.tar*")
      image_files = tar_image_files + TarClient.find("#{TarClient::TAR_IMAGES_DIR}", "*.tgz*")
      #TODO function that loops through all of the tar files that are image files
      #TODO any tar file that is in /tmp is an image file
      #TODO optional any tar file that is in #{TAR_IMAGES_DIR} is an image file
    #   install_list = [{input_file: "/tmp/kubectl.tar"}, 
    #                   {input_file: "/tmp/chaos-mesh.tar"}, 
    #                   {input_file: "/tmp/chaos-daemon.tar"}, 
    #                   {input_file: "/tmp/chaos-dashboard.tar"}, 
    #                   {input_file: "/tmp/chaos-kernel.tar"}, 
    #                   {input_file: "/tmp/pingcap-coredns.tar"}, 
    #                   {input_file: "/tmp/sonobuoy.tar"}, 
    #                   {input_file: "/tmp/sonobuoy-logs.tar"}, 
    #                   {input_file: "/tmp/litmus-operator.tar"}, 
    #                   {input_file: "/tmp/litmus-runner.tar"}, 
    #                   {input_file: "/tmp/prometheus.tar"}]
    end
    # resp = install_list.map {|x| AirGap.publish_tarball(x[:input_file])}
    LOGGING.info "publishing: #{image_files}"
    resp = image_files.map {|x| AirGap.publish_tarball(x)}
    LOGGING.debug "resp: #{resp}"
    resp
  end

  #   # TODO add tar binary to prereqs/documentation
  def self.bootstrap_cluster
    pods = AirGap.pods_with_tar()
    LOGGING.info "TAR POD: #{pods}"
    tar_pod_name =  pods[0].dig?("metadata", "name") if pods[0]?
    LOGGING.info "TAR POD NAME: #{tar_pod_name}"
    unless tar_pod_name 
      LOGGING.info "NO TAR POD, CHECKING FOR PODS WITH SHELL"
      pods = AirGap.pods_with_sh()
      no_tar = true
    end
    #TODO Ensure images found are available on all schedulable nodes on the cluster.
    images = AirGap.pod_images(pods)
    if images.empty?
      raise "No images with Tar or Shell found. Please deploy a Pod with Tar or Shell to your cluster."
    end
    resp = AirGap.create_pod_by_image(images[0], "cri-tools")
    pods = KubectlClient::Get.pods_by_nodes(KubectlClient::Get.schedulable_nodes_list)
    pods = KubectlClient::Get.pods_by_label(pods, "name", "cri-tools")

    cri_tools_pod_name = pods[0].dig?("metadata", "name") if pods[0]?
    if no_tar
      LOGGING.info "NO TAR POD, COPYING TAR FROM HOST"
      tar_path = AirGap.check_tar(cri_tools_pod_name, namespace="default", pod=false)
      pods.map do |pod| 
        KubectlClient.exec("#{pod.dig?("metadata", "name")} -ti -- cp #{tar_path} /usr/local/bin/")
        status = KubectlClient.exec("#{pod.dig?("metadata", "name")} -ti -- /usr/local/bin/tar --version")
        unless status[:status].success?
          raise "No images with Tar or Shell found. Please deploy a Pod with Tar or Shell to your cluster."
        end
      end
    end
    AirGap.install_cri_binaries(pods)
  end

  def self.publish_tarball(tarball)
    pods = KubectlClient::Get.pods_by_nodes(KubectlClient::Get.schedulable_nodes_list)
    pods = KubectlClient::Get.pods_by_label(pods, "name", "cri-tools")
    pods.map do |pod| 
      pod_name = pod.dig?("metadata", "name")
      KubectlClient.cp("#{tarball} #{pod_name}:/tmp/#{tarball.split("/")[-1]}")
    end
    pods.map do |pod| 
      pod_name = pod.dig?("metadata", "name")
      resp = KubectlClient.exec("-ti #{pod_name} -- ctr -n=k8s.io image import /tmp/#{tarball.split("/")[-1]}")
      LOGGING.debug "Resp: #{resp}"
      resp
    end
  end



  #TODO put these in the airgap tarball
  def self.download_cri_tools
    FileUtils.mkdir_p("#{TarClient::TAR_BIN_DIR}")
    LOGGING.info "download_cri_tools"
    `curl -L https://github.com/kubernetes-sigs/cri-tools/releases/download/#{CRI_VERSION}/crictl-#{CRI_VERSION}-linux-amd64.tar.gz --output #{TarClient::TAR_BIN_DIR}/crictl-#{CRI_VERSION}-linux-amd64.tar.gz`
    `curl -L https://github.com/containerd/containerd/releases/download/v#{CTR_VERSION}/containerd-#{CTR_VERSION}-linux-amd64.tar.gz --output #{TarClient::TAR_BIN_DIR}/containerd-#{CTR_VERSION}-linux-amd64.tar.gz`
  end

  def self.untar_cri_tools
    TarClient.untar("#{TarClient::TAR_BIN_DIR}/crictl-#{CRI_VERSION}-linux-amd64.tar.gz", TarClient::TAR_BIN_DIR)
    TarClient.untar("#{TarClient::TAR_BIN_DIR}/containerd-#{CTR_VERSION}-linux-amd64.tar.gz", TarClient::TAR_TMP_BASE)
  end

  def self.pod_images(pods)
    pods.map do |pod|
      containers = pod.dig("spec","containers").as_a
      #TODO make this work with multiple containers
      # Gets first image for every pod
      image = containers[0]? && containers[0].dig("image")
    end
  end

  def self.install_cri_binaries(cri_tool_pods)
    # AirGap.download_cri_tools()
    AirGap.untar_cri_tools()
    cri_tool_pods.map do |pod|
      KubectlClient.cp("#{TarClient::TAR_BIN_DIR}/crictl #{pod.dig?("metadata", "name")}:/usr/local/bin/crictl")
      KubectlClient.cp("#{TarClient::TAR_BIN_DIR}/ctr #{pod.dig?("metadata", "name")}:/usr/local/bin/ctr")
    end
  end

  def self.check_sh(pod_name, namespace="default")
    # --namespace=${POD[1]}
    sh = KubectlClient.exec("--namespace=#{namespace} -ti #{pod_name} -- cat /bin/sh > /dev/null")  
    sh[:status].success?
  end

  def self.check_tar(pod_name, namespace="default", pod=true)
    if pod
      bin_tar = KubectlClient.exec("--namespace=#{namespace} -ti #{pod_name} -- cat /bin/tar > /dev/null")  
      usr_bin_tar =  KubectlClient.exec("--namespace=#{namespace} -ti #{pod_name} -- cat /usr/bin/tar > /dev/null")
      usr_local_bin_tar = KubectlClient.exec("--namespace=#{namespace} -ti #{pod_name} -- cat /usr/local/bin/tar > /dev/null")
    else
      bin_tar = KubectlClient.exec("--namespace=#{namespace} -ti #{pod_name} -- cat /tmp/bin/tar > /dev/null")  
      usr_bin_tar =  KubectlClient.exec("--namespace=#{namespace} -ti #{pod_name} -- cat /tmp/usr/bin/tar > /dev/null")
      usr_local_bin_tar = KubectlClient.exec("--namespace=#{namespace} -ti #{pod_name} -- cat /tmp/usr/local/bin/tar > /dev/null")
    end
    if pod
      (bin_tar[:status].success? && "/bin/tar") || (usr_bin_tar.[:status].success? && "/usr/bin/tar") || (usr_local_bin_tar[:status].success? && "/usr/local/bin/tar")
    else
      (bin_tar[:status].success? && "/tmp/bin/tar") || (usr_bin_tar.[:status].success? && "/tmp/usr/bin/tar") || (usr_local_bin_tar[:status].success? && "/tmp/usr/local/bin/tar")
    end
  end


  # Makes a copy of an image that is already available on the cluster either as:
  #  1. an image, with shell access, that we have determined to already exist
  #  ... or
  #  2. an image (cri-tools) that we have installed into the local docker registry using docker push
  # TODO make this work with runtimes other than containerd
  # TODO make a tool that cleans up the cri images
  def self.create_pod_by_image(image, name="cri-tools")
    template = Crinja.render(cri_tools_template, { "image" => image, "name" => name})
    write = `echo "#{template}" > "#{name}-manifest.yml"`
    KubectlClient::Apply.file("#{name}-manifest.yml")
    KubectlClient::Get.resource_wait_for_install("DaemonSet", name)
  end

  # Make an image all all of the nodes that has tar access
def self.cri_tools_template 
  <<-TEMPLATE
  apiVersion: apps/v1
  kind: DaemonSet
  metadata:
      name: {{ name }}
  spec:
    selector:
      matchLabels:
        name: {{ name }}
    template:
      metadata:
        labels:
          name: {{ name }}
      spec:
        containers:
          - name: {{ name }}
            image: '{{ image }}'
            command: ["/bin/sh"]
            args: ["-c", "sleep infinity"]
            volumeMounts:
            - mountPath: /run/containerd/containerd.sock
              name: containerd-volume
            - mountPath: /tmp/usr/bin
              name: usrbin
            - mountPath: /tmp/usr/local/bin
              name: local
            - mountPath: /tmp/bin
              name: bin
        volumes:
        - name: containerd-volume
          hostPath:
            path: /var/run/containerd/containerd.sock
        - name: usrbin
          hostPath:
            path: /usr/bin/
        - name: local
          hostPath:
            path: /usr/local/bin/
        - name: bin
          hostPath:
            path: /bin/
  TEMPLATE
end

  def self.pods_with_tar() : KubectlClient::K8sManifestList
    pods = KubectlClient::Get.pods_by_nodes(KubectlClient::Get.schedulable_nodes_list).select do |pod|
      pod_name = pod.dig?("metadata", "name")
      namespace = pod.dig?("metadata", "namespace")
      if check_sh(pod_name, namespace) && check_tar(pod_name, namespace, pod=true)
        LOGGING.debug "Found tar and sh Pod: #{pod_name}"
        true
      else
        false
      end
    end
  end

  def self.pods_with_sh() : KubectlClient::K8sManifestList
    pods = KubectlClient::Get.pods_by_nodes(KubectlClient::Get.schedulable_nodes_list).select do |pod|
      pod_name = pod.dig?("metadata", "name")
      namespace = pod.dig?("metadata", "namespace")
      if check_sh(pod_name, namespace) 
        LOGGING.debug "Found sh Pod: #{pod_name}"
        true
      else
        false
      end
    end
  end

  def self.tmp_cleanup
    LOGGING.info "cleaning up /tmp directories, binaries, and tar files"
    `rm -rf /tmp/repositories`
    `rm -rf /tmp/images`
    `rm -rf /tmp/download`
    `rm -rf /tmp/manifests`
    `rm -rf /tmp/bin`
    `rm -rf /tmp/airgapped.tar.gz`
    `rm -rf /tmp/chaos-daemon.tar`
    `rm -rf /tmp/chaos-dashboard.tar`
    `rm -rf /tmp/chaos-daemon.tar`
    `rm -rf /tmp/chaos-mesh.tar`
    `rm -rf /tmp/coredns_1.7.1.tar`
    `rm -rf /tmp/crictl`
    `rm -rf /tmp/kubectl.tar`
    `rm -rf /tmp/litmus-operator.tar`
    `rm -rf /tmp/litmus-runner.tar`
    `rm -rf /tmp/pingcap-coredns.tar`
    `rm -rf /tmp/prometheus.tar`
    `rm -rf /tmp/sonobuoy-logs.tar`
    `rm -rf /tmp/sonobuoy.tar`
  end

end

