# coding: utf-8
require "totem"
require "colorize"
require "crinja"
# require "./tar.cr"
require "tar"
require "find"
# require "./docker_client.cr"
require "docker_client"
require "kubectl_client"
# require "./airgap_utils.cr"
require "file_utils"

# todo put in a separate library. it shold go under ./tools for now
module AirGap
  CRI_VERSION="v1.17.0"
  CTR_VERSION="1.5.0"
  TAR_BOOTSTRAP_IMAGES_DIR = "/tmp/bootstrap_images"
  TAR_REPOSITORY_DIR = "/tmp/repositories"
  TAR_BINARY_DIR = "/tmp/binaries"

  def self.tar_helm_repo(command, output_file : String = "./airgapped.tar.gz")
    Log.info { "tar_helm_repo command: #{command} output_file: #{output_file}" }
    tar_dir = AirGap.helm_tar_dir(command)
    FileUtils.mkdir_p(tar_dir)
    Helm.fetch("#{command} -d #{tar_dir}")
    Log.debug { "ls #{tar_dir}:" + "#{Dir.children(tar_dir)}" }
    info = AirGap.tar_info_by_config_src(command)
    repo = info[:repo]
    repo_dir = info[:repo_dir]
    chart_name = info[:chart_name]
    repo_path = info[:repo_path]
    tar_dir = info[:tar_dir]
    tar_name = info[:tar_name]

    TarClient.modify_tar!(tar_name) do |directory| 
      template_files = Find.find(directory, "*.yaml*", "100")
      template_files.map{|x| AirGap.image_pull_policy(x)}
    end
    TarClient.append(output_file, "/tmp", "#{repo_path}")
  ensure
    FileUtils.rm_rf("/tmp/#{repo_path}")
  end
  
  def self.tar_manifest(url, output_file : String = "./airgapped.tar.gz", prefix="")
    manifest_path = "manifests/" 
    FileUtils.rm_rf("/tmp/#{manifest_path}")
    FileUtils.mkdir_p("/tmp/" + manifest_path)
    manifest_name = prefix + url.split("/").last 
    manifest_full_path = manifest_path + manifest_name 
    Log.info { "manifest_name: #{manifest_name}" }
    Log.info { "manifest_full_path: #{manifest_full_path}" }
    Halite.get("#{url}") do |response| 
       File.open("/tmp/" + manifest_full_path, "w") do |file| 
         IO.copy(response.body_io, file)
       end
    end
    TarClient.append(output_file, "/tmp", manifest_full_path)
  ensure
    FileUtils.rm_rf("/tmp/#{manifest_path}")
  end

  #./cnf-testsuite airgapped -o ~/airgapped.tar.gz
  #./cnf-testsuite offline -o ~/airgapped.tar.gz
  #./cnf-testsuite offline -o ~/mydir/airgapped.tar.gz
  def self.generate(output_file : String = "./airgapped.tar.gz", append=false)
    FileUtils.rm_rf(output_file) unless append
    FileUtils.mkdir_p("#{TAR_BOOTSTRAP_IMAGES_DIR}")
    AirGap.download_cri_tools
    TarClient.append(output_file, TarClient::TAR_TMP_BASE, "bin/crictl-#{CRI_VERSION}-linux-amd64.tar.gz")
    TarClient.append(output_file, TarClient::TAR_TMP_BASE, "bin/containerd-#{CTR_VERSION}-linux-amd64.tar.gz")
  end

  #./cnf-testsuite setup --offline=./airgapped.tar.gz
  def self.extract(output_file : String = "./airgapped.tar.gz", output_dir="/tmp")
    Log.info { "extract" }
    TarClient.untar(output_file, output_dir)
  end

  def self.cache_images(cnf_setup=false, kind_name=false)
    Log.info { "cache_images" }
    unless kind_name
      AirGap.bootstrap_cluster()
    end
    
    #TODO Potentially remove this. 
    if ENV["CRYSTAL_ENV"]? == "TEST"
      # todo change chaos-mesh tar to something more generic
      image_files = ["#{TAR_BOOTSTRAP_IMAGES_DIR}/kubectl.tar", 
                      "#{TAR_BOOTSTRAP_IMAGES_DIR}/chaos-mesh.tar"]
      tar_image_files = Find.find("#{TarClient::TAR_IMAGES_DIR}", "*.tar*")
      image_files = image_files + tar_image_files + Find.find("#{TarClient::TAR_IMAGES_DIR}", "*.tgz*")
    else
      if cnf_setup
        tar_image_files = Find.find("#{TarClient::TAR_IMAGES_DIR}", "*.tar*")
        image_files = tar_image_files + Find.find("#{TarClient::TAR_IMAGES_DIR}", "*.tgz*")
      else
        tar_image_files = Find.find("#{TAR_BOOTSTRAP_IMAGES_DIR}", "*.tar*")
        image_files = tar_image_files + Find.find("#{TAR_BOOTSTRAP_IMAGES_DIR}", "*.tgz*")
      end
    end
    Log.info { "publishing: #{image_files}" }
    resp = image_files.map {|x| AirGap.publish_tarball(x, kind_name)}
    Log.debug { "resp: #{resp}" }
    resp
  end

  #   # TODO add tar binary to prereqs/documentation
  def self.bootstrap_cluster
    pods = AirGap.pods_with_tar()
    Log.info { "TAR POD: #{pods}" }
    tar_pod_name =  pods[0].dig?("metadata", "name") if pods[0]?
    Log.info { "TAR POD NAME: #{tar_pod_name}" }
    unless tar_pod_name 
      Log.info { "NO TAR POD, CHECKING FOR PODS WITH SHELL" }
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
    KubectlClient::Get.wait_for_critools

    cri_tools_pod_name = pods[0].dig?("metadata", "name") if pods[0]?
    if no_tar
      Log.info { "NO TAR POD, COPYING TAR FROM HOST" }
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

  def self.publish_tarball(tarball, kind_name=false)
    unless kind_name
      pods = KubectlClient::Get.pods_by_nodes(KubectlClient::Get.schedulable_nodes_list)
      pods = KubectlClient::Get.pods_by_label(pods, "name", "cri-tools")
      pods.map do |pod| 
        pod_name = pod.dig?("metadata", "name")
        KubectlClient.cp("#{tarball} #{pod_name}:/tmp/#{tarball.split("/")[-1]}")
      end
      pods.map do |pod| 
        pod_name = pod.dig?("metadata", "name")
        resp = KubectlClient.exec("-ti #{pod_name} -- ctr -n=k8s.io image import /tmp/#{tarball.split("/")[-1]}")
        Log.debug { "Resp: #{resp}" }
        resp
      end
    else
      KubectlClient.cp("#{tarball} #{kind_name}:/tmp/#{tarball.split("/")[-1]}")
      KubectlClient.exec("-ti #{kind_name} -- ctr -n=k8s.io image import /tmp/#{tarball.split("/")[-1]}")
    end
  end

  def self.download_cri_tools
    FileUtils.mkdir_p("#{TarClient::TAR_BIN_DIR}")
    Log.info { "download_cri_tools" }
    cmd = "curl -L https://github.com/kubernetes-sigs/cri-tools/releases/download/#{CRI_VERSION}/crictl-#{CRI_VERSION}-linux-amd64.tar.gz --output #{TarClient::TAR_BIN_DIR}/crictl-#{CRI_VERSION}-linux-amd64.tar.gz"
    stdout = IO::Memory.new
    Process.run(cmd, shell: true, output: stdout, error: stdout)

    cmd = "curl -L https://github.com/containerd/containerd/releases/download/v#{CTR_VERSION}/containerd-#{CTR_VERSION}-linux-amd64.tar.gz --output #{TarClient::TAR_BIN_DIR}/containerd-#{CTR_VERSION}-linux-amd64.tar.gz"
    stdout = IO::Memory.new
    Process.run(cmd, shell: true, output: stdout, error: stdout)
  end

  def self.untar_cri_tools
    TarClient.untar("#{TarClient::TAR_BIN_DIR}/crictl-#{CRI_VERSION}-linux-amd64.tar.gz", TarClient::TAR_BIN_DIR)
    TarClient.untar("#{TarClient::TAR_BIN_DIR}/containerd-#{CTR_VERSION}-linux-amd64.tar.gz", TarClient::TAR_TMP_BASE)
  end

  def self.pod_images(pods)
    # todo change into a reduce, loop through all containers and append image 
    #  into final array of images
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
    File.write("#{name}-manifest.yml", template)
    KubectlClient::Apply.file("#{name}-manifest.yml")
    LOGGING.info KubectlClient::Get.resource_wait_for_install("DaemonSet", name)
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
        Log.debug { "Found tar and sh Pod: #{pod_name}" }
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
        Log.debug { "Found sh Pod: #{pod_name}" }
        true
      else
        false
      end
    end
  end


  def self.image_pull_policy_config_file?(install_method, config_src, release_name)
    Log.info { "image_pull_policy_config_file" }
    yml = [] of Array(YAML::Any)
    case install_method
    when Helm::InstallMethod::ManifestDirectory
      file_list = Helm::Manifest.manifest_file_list(config_src, silent=false)
      yml = Helm::Manifest.manifest_ymls_from_file_list(file_list)
    when Helm::InstallMethod::HelmChart, Helm::InstallMethod::HelmDirectory
      Helm.template(release_name, config_src, output_file="cnfs/temp_template.yml") 
      yml = Helm::Manifest.parse_manifest_as_ymls(template_file_name="cnfs/temp_template.yml")
    else
      raise "config source error: #{install_method}"
    end
    container_image_pull_policy?(yml)
  end

  def self.container_image_pull_policy?(yml : Array(YAML::Any))
    Log.info { "container_image_pull_policy" }
    containers  = yml.map { |y|
      mc = Helm::Manifest.manifest_containers(y)
      mc.as_a? if mc
    }.flatten.compact
    Log.debug { "containers : #{containers}" }
    found_all = true 
    containers.flatten.map do |x|
      Log.debug { "container x: #{x}" }
      ipp = x.dig?("imagePullPolicy")
      image = x.dig?("image")
      Log.debug { "ipp: #{ipp}" }
      Log.debug { "image: #{image.as_s}" if image }
      parsed_image = DockerClient.parse_image(image.as_s) if image
      Log.debug { "parsed_image: #{parsed_image}" }
      # if there is no image pull policy, any image that does not have a tag will
      # force a call out to the default image registry
      if ipp == nil && (parsed_image && parsed_image["tag"] == "latest")
        Log.info { "ipp or tag not found with ipp: #{ipp} and parsed_image: #{parsed_image}" }
        found_all = false
      end 
    end
    Log.info { "found_all: #{found_all}" }
    found_all
  end


  def self.image_pull_policy(file, output_file="")
    input_content = File.read(file) 
    output_content = input_content.gsub(/(.*imagePullPolicy:)(.*.)/,"\\1 Never")

    # LOGGING.debug "pull policy found?: #{input_content =~ /(.*imagePullPolicy:)(.*)/}"
    # LOGGING.debug "output_content: #{output_content}"
    if output_file.empty?
      input_content = File.write(file, output_content) 
    else
      input_content = File.write(output_file, output_content) 
    end
    #
    #TODO find out why this doesn't work
    # LOGGING.debug "after conversion: #{File.read(file)}"
  end

  def self.tar_name_by_helm_chart(config_src : String)
    FileUtils.mkdir_p(TAR_REPOSITORY_DIR)
    Log.debug { "tar_name_by_helm_chart ls /tmp/repositories:" + "#{Dir.children("/tmp/repositories")}" }
    tar_dir = helm_tar_dir(config_src)
    tgz_files = Find.find(tar_dir, "*.tgz*")
    tar_files = Find.find(tar_dir, "*.tar*") + tgz_files
    tar_name = ""
    tar_name = tar_files[0] if !tar_files.empty?
    Log.info { "tar_name: #{tar_name}" }
    tar_name
  end

  def self.tar_info_by_config_src(config_src : String)
    FileUtils.mkdir_p(TAR_REPOSITORY_DIR)
    Log.debug { "tar_info_by_config_src ls /tmp/repositories:" + "#{Dir.children("/tmp/repositories")}" }
    # chaos-mesh/chaos-mesh --version 0.5.1
    repo = config_src.split(" ")[0]
    repo_dir = repo.gsub("/", "_")
    chart_name = repo.split("/")[-1]
    repo_path = "repositories/#{repo_dir}" 
    tar_dir = "/tmp/#{repo_path}"
    tar_info = {repo: repo, repo_dir: repo_dir, chart_name: chart_name,
     repo_path: repo_path, tar_dir: tar_dir, tar_name: tar_name_by_helm_chart(config_src)}
    Log.info { "tar_info: #{tar_info}" }
    tar_info
  end

  def self.helm_tar_dir(config_src : String)
    FileUtils.mkdir_p(TAR_REPOSITORY_DIR)
    Log.debug { "helm_tar_dir ls /tmp/repositories:" + "#{Dir.children("/tmp/repositories")}" }
    # chaos-mesh/chaos-mesh --version 0.5.1
    repo = config_src.split(" ")[0]
    repo_dir = repo.gsub("/", "_")
    chart_name = repo.split("/")[-1]
    repo_path = "repositories/#{repo_dir}" 
    tar_dir = "/tmp/#{repo_path}"
    Log.info { "helm_tar_dir: #{tar_dir}" }
    tar_dir
  end

  # todo separate cnf-test-suite cleanup from airgap generic cleanup
  # todo force process.run instead of backtick
  def self.tmp_cleanup
    Log.info { "cleaning up /tmp directories, binaries, and tar files" }
    paths = [
      "/tmp/repositories",
      "/tmp/images",
      "/tmp/bootstrap_images",
      "/tmp/download",
      "/tmp/manifests",
      "/tmp/bin",
      "/tmp/airgapped.tar.gz",
      "/tmp/chaos-daemon.tar",
      "/tmp/chaos-dashboard.tar",
      "/tmp/chaos-daemon.tar",
      "/tmp/chaos-mesh.tar",
      "/tmp/coredns_1.7.1.tar",
      "/tmp/crictl",
      "/tmp/kubectl.tar",
      "/tmp/litmus-operator.tar",
      "/tmp/litmus-runner.tar",
      "/tmp/pingcap-coredns.tar",
      "/tmp/prometheus.tar",
      "/tmp/sonobuoy-logs.tar",
      "/tmp/sonobuoy.tar"
    ]
    FileUtils.rm_rf(paths)
  end

end
