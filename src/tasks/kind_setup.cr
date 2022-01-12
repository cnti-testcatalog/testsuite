require "sam"
require "file_utils"
require "colorize"
require "totem"
require "./utils/utils.cr"
require "retriable"

desc "Install Kind"
task "install_kind" do |_, args|
  Log.info {"install_kind"}
  current_dir = FileUtils.pwd 
  unless Dir.exists?("#{current_dir}/#{TOOLS_DIR}/kind")
    FileUtils.mkdir_p("#{current_dir}/#{TOOLS_DIR}/kind") 
    write_file = "#{current_dir}/#{TOOLS_DIR}/kind/kind"
    Log.info { "write_file: #{write_file}" }
    if args.named["offline"]?
        Log.info { "install kind offline mode" }
        FileUtils.cp("#{TarClient::TAR_DOWNLOAD_DIR}/kind", "#{write_file}")
      stderr = IO::Memory.new
      status = Process.run("chmod +x #{write_file}", shell: true, output: stderr, error: stderr)
      success = status.success?
      raise "Unable to make #{write_file} executable" if success == false
    else
      Log.info { "install kind online mode" }
      url = "https://github.com/kubernetes-sigs/kind/releases/download/v#{KIND_VERSION}/kind-linux-amd64"
      Log.info { "url: #{url}" }
      do_this_on_each_retry = ->(ex : Exception, attempt : Int32, elapsed_time : Time::Span, next_interval : Time::Span) do
          Log.info { "#{ex.class}: '#{ex.message}' - #{attempt} attempt in #{elapsed_time} seconds and #{next_interval} seconds until the next try."}
      end
      Retriable.retry(on_retry: do_this_on_each_retry, times: 3, base_interval: 1.second) do
        resp = Halite.follow.get("#{url}") do |response| 
          File.write("#{write_file}", response.body_io)
        end 
        Log.debug {"resp: #{resp}"}
        case resp.status_code
        when 403, 404
          raise "Unable to download: #{url}" 
        end
        stderr = IO::Memory.new
        status = Process.run("chmod +x #{write_file}", shell: true, output: stderr, error: stderr)
        success = status.success?
        raise "Unable to make #{write_file} executable" if success == false
      end
    end
  end
end

desc "Uninstall Kind"
task "uninstall_kind" do |_, args|
  current_dir = FileUtils.pwd 
  Log.for("verbose").info { "uninstall_kind" } if check_verbose(args)
  FileUtils.rm_rf("#{current_dir}/#{TOOLS_DIR}/kind")
end

# USAGE:
#
# To create a kind cluster called hello, with no kind config
#
#     kind_manager = KindManager.new
#     kind_manager.create_cluster("hello", nil, false)
#
class KindManager
  # Project root based on which tools dir would be determined
  property project_root : String

  # Path to helm
  property helm : String

  # Path to kind
  property kind : String

  def initialize
    @project_root = FileUtils.pwd
    @helm = BinarySingleton.helm
    @kind = "#{project_root}/#{TOOLS_DIR}/kind/kind"
    Log.for("kind_project_root").info { project_root }
  end

  #totod make a create cluster with flannel

  def create_cluster(name : String, kind_config : String?, offline : Bool, k8s_version = "1.21.1") : KindManager::Cluster?
    Log.info { "Creating Kind Cluster" }
    kubeconfig = "#{project_root}/#{TOOLS_DIR}/kind/#{name}_admin.conf"
    Log.for("kind_kubeconfig").info { kubeconfig }

    kind_config_opt = ""
    if kind_config != nil
      kind_config_opt = "--config #{kind_config}"
    end

    unless File.exists?("#{kubeconfig}")
      # Debug notes:
      # * Add --verbosity 100 to debug kind issues.
      # * Use --retain to retain cluster incase there is an error with creation.
      cmd = "#{kind} create cluster --name #{name} #{kind_config_opt} --image kindest/node:v#{k8s_version} --kubeconfig #{kubeconfig}"
      if offline
        ShellCmd.run(cmd, "KindManager#create_cluster(offline)")
      else
        ShellCmd.run(cmd, "KindManager#create_cluster(online)")
      end
    end

    return KindManager::Cluster.new(name, kubeconfig)
  end

  def delete_cluster(name)
    Log.info {"Deleting Kind Cluster: #{name}"}
    ShellCmd.run("#{kind} delete cluster --name #{name}", "KindManager#delete_cluster")

    if File.exists? "#{project_root}/#{TOOLS_DIR}/kind/#{name}_admin.conf"
      Log.info {"Deleting kubeconfig for kind cluster: #{name}"}
      File.delete "#{project_root}/#{TOOLS_DIR}/kind/#{name}_admin.conf"
    end
  end

  def self.disable_cni_config
    project_root = FileUtils.pwd
    kind_config = "#{project_root}/#{TOOLS_DIR}/kind/disable_cni.yml"
    unless File.exists?(kind_config)
      File.write(kind_config, DISABLE_CNI)
    end

    kind_config
  end

  def self.create_cluster_with_chart_and_wait(name, kind_config, chart_opts, offline) : KindManager::Cluster
    manager = KindManager.new
    cluster = manager.create_cluster(name, kind_config, offline)
    Helm.install("#{name}-plugin #{chart_opts} --namespace kube-system --kubeconfig #{cluster.kubeconfig}")
    cluster.wait_until_pods_ready()
    cluster
  end

  class Cluster
    property name
    property kubeconfig

    def initialize(@name : String, @kubeconfig : String)
    end

    def wait_until_nodes_ready(wait_count : Int32 = 180)
      Log.info { "wait_until_nodes_ready" }
      ready = false
      timeout = wait_count
      until (ready == true || timeout <= 0)
        cmd = "kubectl get nodes --kubeconfig #{kubeconfig}"
        result = ShellCmd.run(cmd, "wait_until_nodes_ready:all_nodes")
        all_nodes = result[:output]
        Log.info { "all_nodes: #{all_nodes}" }

        all_nodes = all_nodes.split("\n")
        range_end = all_nodes.size - 2
        all_nodes = all_nodes[1..range_end]
        node_count = all_nodes.size
        Log.info { "node_count: #{node_count}" }

        ready_count  = all_nodes.reduce(0) do |acc, node|
          if /\s(Ready)/.match(node)
            acc = acc + 1
          else
            acc
          end
        end

        if node_count == ready_count
          Log.info { "Nodes are ready for the #{name} cluster" }
          ready = true
        else
          sleep 1
          timeout = timeout - 1
          Log.info { "Waiting for nodes on #{name} cluster to be ready: #{ready}" }
          break if timeout <= 0
        end
      end
      ready
    end

    def wait_until_pods_ready(wait_count : Int32 = 180)
      Log.info { "wait_until_pods_ready" }
      ready = false
      timeout = wait_count
      until (ready == true || timeout <= 0)
        all_pods_cmd = <<-STRING
        kubectl get pods -A -o go-template='{{range $index, $element := .items}}{{range .status.containerStatuses}}{{$element.metadata.name}}{{"\\n"}}{{end}}{{end}}'  --kubeconfig #{kubeconfig}
        STRING
        result = ShellCmd.run(all_pods_cmd, "wait_until_pods_ready:all_pods")
        all_pods = result[:output]
        Log.info { "all_pods: #{all_pods}" }
        # Reducing count by 1 because the blank last line in the output will also be counted.
        pod_count  = (all_pods.split("\n").reduce(0) {|acc,x| acc+1}) - 1
        Log.info { "pod_count: #{pod_count}" }

        ready_pods_cmd = <<-STRING
        kubectl get pods -A -o go-template='{{range $index, $element := .items}}{{range .status.containerStatuses}}{{if .ready}}{{$element.metadata.name}}{{"\\n"}}{{end}}{{end}}{{end}}'  --kubeconfig #{kubeconfig}
        STRING

        result = ShellCmd.run(ready_pods_cmd, "wait_until_pods_ready:get_ready_pods")
        ready_pods = result[:output]
        Log.info { "ready_pods: #{ready_pods}" }

        # Reducing count by 1 because the last blank line in the output will also be counted.
        ready_count  = (ready_pods.split("\n").reduce(0) {|acc,x| acc+1}) - 1
        Log.info { "pod_ready_count: #{ready_count}" }

        if pod_count.to_i == ready_count.to_i
          Log.info { "Pods on #{name} cluster are ready" }
          ready = true
        else
          sleep 1
          timeout = timeout - 1
          Log.info { "Waiting for pods on #{name} cluster to be ready: #{ready}" }
          break if timeout <= 0
        end
      end
      ready
    end

  end
end
