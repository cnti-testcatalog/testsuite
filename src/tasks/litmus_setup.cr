# coding: utf-8
require "sam"
require "file_utils"
require "colorize"
require "totem"
require "./utils/utils.cr"

desc "Install LitmusChaos"
task "install_litmus" do |_, args|
  if args.named["offline"]?
    Log.info {"install litmus offline mode"}
    AirGap.image_pull_policy(LitmusManager::OFFLINE_LITMUS_OPERATOR)
    KubectlClient::Apply.file(LitmusManager::OFFLINE_LITMUS_OPERATOR)
    KubectlClient::Apply.file("#{OFFLINE_MANIFESTS_PATH}/chaos_crds.yaml")
  else
    #todo in resilience node_drain task
    #todo get node name 
    #todo download litmus file then modify it with add_node_selector
    #todo apply modified litmus file
    Log.info { "install litmus online mode" }
    Log.info { "install litmus operator"}
    KubectlClient::Apply.namespace(LitmusManager::LITMUS_NAMESPACE) 
    KubectlClient::Apply.file(LitmusManager::ONLINE_LITMUS_OPERATOR)
  end
end

desc "Uninstall LitmusChaos"
task "uninstall_litmus" do |_, args|
  uninstall_chaosengine_cmd = "kubectl delete chaosengine --all --all-namespaces"
  status = Process.run(
      uninstall_chaosengine_cmd,
      shell: true,
      output: stdout = IO::Memory.new,
      error: stderr = IO::Memory.new
  )
  if args.named["offline"]?
    Log.info { "install litmus offline mode" }
    KubectlClient::Delete.file("#{OFFLINE_MANIFESTS_PATH}/litmus-operator-v#{LitmusManager::Version}.yaml")
  else
    KubectlClient::Delete.file("https://litmuschaos.github.io/litmus/litmus-operator-v#{LitmusManager::Version}.yaml")
  end
  Log.info { "#{stdout}" if check_verbose(args) }
  Log.info { "#{stderr}" if check_verbose(args) }
end

module LitmusManager

  Version = "3.6.0"
  RBAC_VERSION = "2.6.0"
  # Version = "1.13.8"
  # Version = "3.0.0-beta12"
  NODE_LABEL = "kubernetes.io/hostname"
  OFFLINE_LITMUS_OPERATOR = "#{OFFLINE_MANIFESTS_PATH}/litmus-operator-v#{LitmusManager::Version}.yaml"
  #https://raw.githubusercontent.com/litmuschaos/chaos-operator/v2.14.x/deploy/operator.yaml
  # ONLINE_LITMUS_OPERATOR = "https://litmuschaos.github.io/litmus/litmus-operator-v#{LitmusManager::Version}.yaml"
  ONLINE_LITMUS_OPERATOR = "https://litmuschaos.github.io/litmus/litmus-operator-v#{LitmusManager::Version}.yaml"
  # for node drain
  DOWNLOADED_LITMUS_FILE = "litmus-operator-downloaded.yaml"
  MODIFIED_LITMUS_FILE = "litmus-operator-modified.yaml"
  LITMUS_NAMESPACE = "litmus"



  def self.add_node_selector(node_name, airgap=false )
    if airgap
      file = File.read(OFFLINE_LITMUS_OPERATOR)

    else
      file = File.read(DOWNLOADED_LITMUS_FILE)
    end
    deploy_index = file.index("kind: Deployment") || 0 
    spec_literal = "spec:"
    template = "\n      nodeSelector:\n        kubernetes.io/hostname: #{node_name}"
    spec1_index = file.index(spec_literal, deploy_index + 1)  || 0
    spec2_index = file.index(spec_literal, spec1_index + 1) || 0
    output_file = file.insert(spec2_index + spec_literal.size, template) unless spec2_index == 0
    File.write(MODIFIED_LITMUS_FILE, output_file) unless output_file == nil
  end

  def self.get_target_node_to_cordon(deployment_label, deployment_value, namespace)
    app_nodeName_cmd = "kubectl get pods -l #{deployment_label}=#{deployment_value} -n #{namespace} -o=jsonpath='{.items[0].spec.nodeName}'"
    Log.info { "Getting the operator node name: #{app_nodeName_cmd}" }
    status_code = Process.run("#{app_nodeName_cmd}", shell: true, output: appNodeName_response = IO::Memory.new, error: stderr = IO::Memory.new).exit_status
    Log.for("verbose").info { "status_code: #{status_code}" } 
    appNodeName_response.to_s
  end

  ## wait_for_test will wait for the completion of litmus test
  def self.wait_for_test(test_name, chaos_experiment_name,total_chaos_duration,args, namespace : String = "default")
    ## Maximum wait time is TCD (total chaos duration) + 60s (additional wait time)
    delay=2
    timeout="#{total_chaos_duration}".to_i + 60
    retry=timeout/delay
    chaos_result_name = "#{test_name}-#{chaos_experiment_name}"
    wait_count = 0
    status_code = -1
    experimentStatus = ""
    
    experimentStatus_cmd = "kubectl get chaosengine.litmuschaos.io #{test_name} -n #{namespace} -o jsonpath='{.status.engineStatus}'"
    Log.for("wait_for_test").info { "Checking experiment status #{experimentStatus_cmd}" } if check_verbose(args)

    ## Wait for completion of chaosengine which indicates the completion of chaos
    until (status_code == 0 && experimentStatus == "Completed") || wait_count >= 1800
      sleep delay
      experimentStatus_cmd = "kubectl get chaosengine.litmuschaos.io #{test_name}  -n #{namespace} -o jsonpath='{.status.experiments[0].status}'"
      Log.for("wait_for_test").info { "Checking experiment status  #{experimentStatus_cmd}" } if check_verbose(args)
      status_code = Process.run("#{experimentStatus_cmd}", shell: true, output: experimentStatus_response = IO::Memory.new, error: stderr = IO::Memory.new).exit_status
      Log.for("wait_for_test").info { "status_code: #{status_code}" } if check_verbose(args)
      Log.for("wait_for_test").info { "Checking experiment status  #{experimentStatus_cmd}" } if check_verbose(args)
      experimentStatus = experimentStatus_response.to_s
      Log.info {"#{chaos_experiment_name} experiment status: "+experimentStatus}

      emoji_test_failed= "🗡️💀♻️"
      Log.info { "experimentStatus #{experimentStatus}"}
      if (experimentStatus != "Waiting for Job Creation" && experimentStatus != "Running" && experimentStatus != "Completed")
        Log.info {"#{test_name}: wait_for_test failed."}
      end
      wait_count = wait_count + 1
    end

    verdict = ""
    wait_count = 0
    verdict_cmd = "kubectl get chaosresults.litmuschaos.io #{chaos_result_name}  -n #{namespace} -o jsonpath='{.status.experimentStatus.verdict}'"
    Log.for("wait_for_test").info { "Checking experiment verdict  #{verdict_cmd}" } if check_verbose(args)
    ## Check the chaosresult verdict
    until (status_code == 0 && verdict != "Awaited") || wait_count >= 30
      sleep delay
      status_code = Process.run("#{verdict_cmd}", shell: true, output: verdict_response = IO::Memory.new, error: stderr = IO::Memory.new).exit_status
      Log.for("wait_for_test").info { "status_code: #{status_code}" } if check_verbose(args)
      Log.for("wait_for_test").info { "verdict: #{verdict_response.to_s}" } if check_verbose(args)
      verdict = verdict_response.to_s
      wait_count = wait_count + 1
    end
  end

  ## check_chaos_verdict will check the verdict of chaosexperiment
  def self.check_chaos_verdict(chaos_result_name, chaos_experiment_name, args, namespace : String = "default") : Bool
    verdict_cmd = "kubectl get chaosresults.litmuschaos.io #{chaos_result_name} -n #{namespace} -o jsonpath='{.status.experimentStatus.verdict}'"
    Log.for("LitmusManager.check_chaos_verdict").debug { "Checking experiment verdict with command: #{verdict_cmd}" }
    status_code = Process.run("#{verdict_cmd}", shell: true, output: verdict_response = IO::Memory.new, error: stderr = IO::Memory.new).exit_status
    Log.for("LitmusManager.check_chaos_verdict").debug { "status_code: #{status_code}; verdict: #{verdict_response.to_s}" }
    verdict = verdict_response.to_s

    emoji_test_failed= "🗡️💀♻️"
    if verdict == "Pass"
      return true
    else
      Log.for("LitmusManager.check_chaos_verdict#details").debug do
        verdict_details_cmd = "kubectl get chaosresults.litmuschaos.io #{chaos_result_name} -n #{namespace} -o json"
        status_code = Process.run("#{verdict_details_cmd}", shell: true, output: verdict_details_response = IO::Memory.new, error: stderr = IO::Memory.new).exit_status
        "#{verdict_details_response.to_s}"
      end

      Log.for("LitmusManager.check_chaos_verdict").info {"#{chaos_experiment_name} chaos test failed: #{chaos_result_name}, verdict: #{verdict}"}
      return false
    end
  end

  def self.chaos_manifests_path
    Log.info {"chaos_manifests_path"}
    chaos_manifests = "#{tools_path}/chaos-experiments"
    if !Dir.exists?(chaos_manifests)
      FileUtils.mkdir_p(chaos_manifests)
    end
    chaos_manifests
  end

  def self.download_template(url, filename)
    Log.info {"download_template url, filename: #{url}, #{filename}"}
    cmp = chaos_manifests_path()
    filepath = "#{cmp}/#{filename}"
    Log.info {"filepath: #{filepath}"}

    HttpHelper.download(url, filepath)

    filepath
  end
end
