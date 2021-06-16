# coding: utf-8
require "totem"
require "colorize"
require "crinja"
require "./tar.cr"
require "./docker_client.cr"
require "./kubectl_client.cr"
require "./airgap_utils.cr"

# todo put in a separate library. it shold go under ./tools for now
module AirGap
  CRI_VERSION="v1.17.0"
  CTR_VERSION="1.5.0"
  TAR_REPOSITORY_DIR = "/tmp/repositories"

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
  def self.generate_cnf_setup(config_file : String, output_file)
    LOGGING.info "generate_cnf_setup cnf_config_file: #{config_file}"
    FileUtils.mkdir_p("#{TarClient::TAR_IMAGES_DIR}")
    config = CNFManager.parsed_config_file(config_file)
    install_method = CNFManager.cnf_installation_method(config)
    #TODO get images from helm chart
    #TODO tarball the images
    LOGGING.info "generate_cnf_setup images_from_config_src"
    images = CNFManager::GenerateConfig.images_from_config_src(install_method[1], generate_tar_mode: true) 

    images.map  do |i|
      input_file = "#{TarClient::TAR_IMAGES_DIR}/#{i[:image_name].split("/")[-1]}_#{i[:tag]}.tar"
      LOGGING.info "input_file: #{input_file}"
      image = "#{i[:image_name]}:#{i[:tag]}"
      DockerClient.pull(image)
      DockerClient.save(image, input_file)
      # FileUtils.mkdir_p("#{TarClient::TAR_IMAGES_DIR}/#{Path[input_file].parent}")
      # TarClient.append(output_file, Path[input_file].parent, "/images/" + input_file.split("/")[-1])
      TarClient.append(output_file, "/tmp", "images/" + input_file.split("/")[-1])
      LOGGING.info "#{output_file} in generate_cnf_setup complete"
    end
    case install_method[0]
    when :helm_chart
      LOGGING.debug "helm_chart : #{install_method[1]}"
      AirGap.tar_helm_repo(install_method[1], output_file)
      LOGGING.info "generate_cnf_setup tar_helm_repo complete"
      when :helm_directory
        LOGGING.debug "helm_directory install method: #{config_file}/#{install_method[1]}"
        yml_path = CNFManager.ensure_cnf_testsuite_dir(config_file)
        release_name = CNFManager.helm_chart_template_release_name("#{yml_path}/#{install_method[1]}")
      when :manifest_directory
        LOGGING.debug "manifest_directory install method"
        release_name = UUID.random.to_s
    else
      raise "Install method should be either helm_chart, helm_directory, or manifest_directory"
    end
  end

  def self.helm_tar_dir(config_src)
    FileUtils.mkdir_p(TAR_REPOSITORY_DIR)
    LOGGING.debug "helm_tar_dir ls /tmp/repositories:" + `ls -al /tmp/repositories`
    # chaos-mesh/chaos-mesh --version 0.5.1
    repo = config_src.split(" ")[0]
    repo_dir = repo.gsub("/", "_")
    chart_name = repo.split("/")[-1]
    repo_path = "repositories/#{repo_dir}" 
    tar_dir = "/tmp/#{repo_path}"
    LOGGING.info "helm_tar_dir: #{tar_dir}"
    tar_dir
  end

  def self.tar_name_by_helm_chart(config_src)
    FileUtils.mkdir_p(TAR_REPOSITORY_DIR)
    LOGGING.debug "tar_name_by_helm_chart ls /tmp/repositories:" + `ls -al /tmp/repositories`
    tar_dir = helm_tar_dir(config_src)
    tgz_files = TarClient.find(tar_dir, "*.tgz*")
    tar_files = TarClient.find(tar_dir, "*.tar*") + tgz_files
    tar_name = ""
    tar_name = tar_files[0] if !tar_files.empty?
    LOGGING.info "tar_name: #{tar_name}"
    tar_name
  end

  def self.tar_info_by_config_src(config_src)
    FileUtils.mkdir_p(TAR_REPOSITORY_DIR)
    LOGGING.debug "tar_info_by_config_src ls /tmp/repositories:" + `ls -al /tmp/repositories`
    # chaos-mesh/chaos-mesh --version 0.5.1
    repo = config_src.split(" ")[0]
    repo_dir = repo.gsub("/", "_")
    chart_name = repo.split("/")[-1]
    repo_path = "repositories/#{repo_dir}" 
    tar_dir = "/tmp/#{repo_path}"
    tar_info = {repo: repo, repo_dir: repo_dir, chart_name: chart_name,
     repo_path: repo_path, tar_dir: tar_dir, tar_name: tar_name_by_helm_chart(config_src)}
    LOGGING.info "tar_info: #{tar_info}"
    tar_info
  end

  # todo airgap_helm_chart << prepare a helm_chart tar file for deployment into an airgapped environment, put in airgap module
  # todo airgap_helm_directory << prepare a helm directory for deployment into an airgapped environment, put in airgap module
  # todo airgap_manifest_directory << prepare a manifest directory for deployment into an airgapped environment, put in airgap module
  #TODO move helm utilities into helm-tar utilty file or into helm file
  def self.tar_helm_repo(command, output_file : String = "./airgapped.tar.gz")
    LOGGING.info "tar_helm_repo command: #{command} output_file: #{output_file}"
    # get the chart name out of the command
    # chaos-mesh/chaos-mesh --version 0.5.1
    #
    tar_dir = helm_tar_dir(command)
    FileUtils.mkdir_p(tar_dir)
    Helm.fetch("#{command} -d #{tar_dir}")
    LOGGING.debug "ls #{tar_dir}:" + `ls -al #{tar_dir}`
    info = tar_info_by_config_src(command)
    repo = info[:repo]
    repo_dir = info[:repo_dir]
    chart_name = info[:chart_name]
    repo_path = info[:repo_path]
    tar_dir = info[:tar_dir]
    tar_name = info[:tar_name]

    # LOGGING.debug "ls /tmp/repositories:" + `ls -al /tmp/repositories`
    # LOGGING.debug "ls #{tar_dir}:" + `ls -al #{tar_dir}`
    # TarClient.untar(tar_name, tar_dir)
    # `rm #{tar_name}` if File.exists?(tar_name)
    # LOGGING.debug "ls #{tar_dir}:" + `ls -al #{tar_dir}`
    # # todo separate out into function that takes a directory name
    # # todo call this in the cnf setup install when in offline mode
    # template_files = TarClient.find(tar_dir, "*.yaml*", "100")
    # LOGGING.debug "template_files: #{template_files}"
    # # resp = yield template_files
    # # AirGapUtils.image_pull_policy(template_files[0])
    # template_files.map{|x| AirGapUtils.image_pull_policy(x)}
    # # TODO look for yml as well
    # # TODO handle recursive/dependend helm charts
    # # TODO function for looping through all yml files in a directory
    # # TODO open the current file if it is a yml file and change the manifest to use image_pull_policy
    # helm_chart = Dir.entries("/tmp/#{repo_path}").first
    # raise "Critical Error" if tar_dir.empty? || tar_dir == '/'
    # # TarClient.append(tar_name, tar_dir, chart_name, "-z")
    # TarClient.tar(tar_name, tar_dir, chart_name)
    # #TODO rm client that checks path for /
    # `rm -rf #{tar_dir}/#{chart_name}`

    TarClient.modify_tar!(tar_name) do |directory| 
      template_files = TarClient.find(directory, "*.yaml*", "100")
      template_files.map{|x| AirGapUtils.image_pull_policy(x)}
    end
    TarClient.append(output_file, "/tmp", "#{repo_path}")
  ensure
    `rm -rf /tmp/#{repo_path} > /dev/null 2>&1`
  end
  
  #TODO create tar_helm_directory
  #TODO create tar_manifest_directory
  #TODO change to tar_manifest_by_url
  def self.tar_manifest(url, output_file : String = "./airgapped.tar.gz", prefix="")
    manifest_path = "manifests/" 
    `rm -rf /tmp/#{manifest_path} > /dev/null 2>&1`
    FileUtils.mkdir_p("/tmp/" + manifest_path)
    manifest_name = prefix + url.split("/").last 
    # manifest_full_path = manifest_path + url.split("/").last
    manifest_full_path = manifest_path + manifest_name 
    LOGGING.info "manifest_name: #{manifest_name}"
    LOGGING.info "manifest_full_path: #{manifest_full_path}"
    Halite.get("#{url}") do |response| 
      #TODO response.body_io to use image_pull_policy
       File.open("/tmp/" + manifest_full_path, "w") do |file| 
         IO.copy(response.body_io, file)
       end
    end
    TarClient.append(output_file, "/tmp", manifest_full_path)
  ensure
    `rm -rf /tmp/#{manifest_path} > /dev/null 2>&1`
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
    TarClient.append(output_file, TarClient::TAR_TMP_BASE, "bin/crictl-#{CRI_VERSION}-linux-amd64.tar.gz")
    TarClient.append(output_file, TarClient::TAR_TMP_BASE, "bin/containerd-#{CTR_VERSION}-linux-amd64.tar.gz")
    AirGap.tar_manifest("https://litmuschaos.github.io/litmus/litmus-operator-v1.13.2.yaml", output_file)
    AirGap.tar_manifest("https://hub.litmuschaos.io/api/chaos/1.13.2?file=charts/generic/pod-network-latency/experiment.yaml", output_file)
    AirGap.tar_manifest("https://hub.litmuschaos.io/api/chaos/1.13.2?file=charts/generic/pod-network-latency/rbac.yaml", output_file)
    AirGap.tar_manifest("https://hub.litmuschaos.io/api/chaos/1.13.2?file=charts/generic/disk-fill/experiment.yaml", output_file, "disk-fill-")
    AirGap.tar_manifest("https://hub.litmuschaos.io/api/chaos/1.13.2?file=charts/generic/disk-fill/rbac.yaml", output_file, "disk-fill-")
    url = "https://github.com/vmware-tanzu/sonobuoy/releases/download/v#{SONOBUOY_K8S_VERSION}/sonobuoy_#{SONOBUOY_K8S_VERSION}_#{SONOBUOY_OS}_amd64.tar.gz"
    TarClient.tar_file_by_url(url, output_file, "sonobuoy.tar.gz")
    Helm.helm_repo_add("chaos-mesh", "https://charts.chaos-mesh.org")
    AirGap.tar_helm_repo("chaos-mesh/chaos-mesh --version 0.5.1", output_file)
  end

  #./cnf-testsuite setup --offline=./airgapped.tar.gz
  def self.extract(output_file : String = "./airgapped.tar.gz", output_dir="/tmp")
    LOGGING.info "extract"
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

