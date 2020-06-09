# coding: utf-8
require "sam"
require "colorize"
require "crinja"
# require "./utils/utils.cr"

desc "The CNF conformance suite checks to see if the CNFs are resilient to failures."
task "resilience", ["restarts_on_kill"] do |t, args|
  puts "resilience args.raw: #{args.raw}" if check_verbose(args)
  puts "resilience args.named: #{args.named}" if check_verbose(args)
end

desc "Install Litmus Chaos Tests"
task "install_litmus" do |_, args|
    # TODO: only install if not already installed
    litmus_install = `kubectl create -f https://litmuschaos.github.io/pages/litmus-operator-latest.yaml`
    puts "#{litmus_install}" if check_verbose(args)
    #ait for deployment
end

desc "Does the CNF come back up when the container is killed"
task "restarts_on_kill", ["install_litmus", "retrieve_manifest"] do |_, args|
# task "restarts_on_kill", ["retrieve_manifest"] do |_, args|
  task_response = task_runner(args) do |args|
    config = parsed_config_file(ensure_cnf_conformance_yml_path(args.named["cnf-config"].as(String)))
    destination_cnf_dir = cnf_destination_dir(ensure_cnf_conformance_dir(args.named["cnf-config"].as(String)))
    deployment_name = config.get("deployment_name").as_s
    deployment_label = config.get("deployment_label").as_s
    helm_chart_container_name = config.get("helm_chart_container_name").as_s
    puts "#{destination_cnf_dir}"
    LOGGING.info "destination_cnf_dir #{destination_cnf_dir}"
    deployment = Totem.from_file "#{destination_cnf_dir}/manifest.yml"
    install_experiment = `kubectl apply -f https://raw.githubusercontent.com/litmuschaos/chaos-charts/master/charts/generic/container-kill/experiment.yaml`
    install_rbac = `kubectl apply -f https://raw.githubusercontent.com/litmuschaos/chaos-charts/master/charts/generic/container-kill/rbac.yaml`
    annotate = `kubectl annotate deploy/#{deployment_name} litmuschaos.io/chaos="true"`
    puts "#{install_experiment}" if check_verbose(args)
    puts "#{install_rbac}" if check_verbose(args)
    puts "#{annotate}" if check_verbose(args)
    #TODO capture the deployment label because it might be nil


    if !ENV.has_key?("DOCKER_HOST")
      # NOTE: DOCKER_HOST is needed for the pumba engine to run it is set by default but the choas test wont work with docker without it
      upsert_failed_task("restarts_on_kill","✖️  FAILURE: docker host not set")
    end

    errors = 0
    begin
      deployment_label_value = deployment.get("metadata").as_h["labels"].as_h[deployment_label].as_s
    rescue ex
      errors = errors + 1
      puts ex.message 
    end

    chaos_experiment_name = "container-kill"
    test_name = "#{deployment_name}-conformance-#{Time.local.to_unix}" 
    verdict_name = "#{test_name}-#{chaos_experiment_name}"

    if errors < 1
      template = Crinja.render(chaos_template__restarts_on_kill, { 
        "chaos_experiment_name"=> "#{chaos_experiment_name}", "test_name" => test_name , "helm_chart_container_name" => "#{helm_chart_container_name}", "deployment_label" => "#{deployment_label}" , "deployment_label_value" => "#{deployment_label_value}" 
      })
      chaos_config = `echo "#{template}" > "#{destination_cnf_dir}/#{chaos_experiment_name}-chaosengine.yml"`
      puts "#{chaos_config}" if check_verbose(args)
      run_chaos = `kubectl create -f "#{destination_cnf_dir}/#{chaos_experiment_name}-chaosengine.yml"`
      puts "#{run_chaos}" if check_verbose(args)
    else
      resp = upsert_failed_task("restarts_on_kill","✖️  FAILURE: No deployment label found for container kill test")
    end

    describe_chaos_result = "kubectl describe chaosresults.litmuschaos.io #{verdict_name}"
    puts "initial checkin of #{describe_chaos_result}" if check_verbose(args)  
    puts "DOCKER_HOST: #{ENV["DOCKER_HOST"]}"
    puts `#{describe_chaos_result}` if check_verbose(args)  

    wait_count = 0 # going up to 20 mins so 20
    status_code = -1 # just a random number to start with
    verdict = ""
    verdict_cmd = "kubectl get chaosresults.litmuschaos.io #{verdict_name} -o jsonpath='{.status.experimentstatus.verdict}'" 
    puts "awating verdict of #{verdict_cmd}" if check_verbose(args)

    until (status_code == 0 && verdict != "Awaited") || wait_count >= 20
      sleep 60
      status_code = Process.run("#{verdict_cmd}", shell: true, output: verdict_response = IO::Memory.new, error: stderr = IO::Memory.new).exit_status 
      puts "status_code: #{status_code}" if check_verbose(args)  
      puts "verdict: #{verdict_response.to_s}"  if check_verbose(args)  
      verdict = verdict_response.to_s 
      wait_count = wait_count + 1
    end

    puts `#{describe_chaos_result}` if check_verbose(args)  

    if verdict == "Pass"
      resp = upsert_passed_task("restarts_on_kill","✔️  PASSED: #{chaos_experiment_name} chaos test passed 🗡️💀♻️")
    else
      resp = upsert_failed_task("restarts_on_kill","✖️  FAILURE: #{chaos_experiment_name} chaos test failed 🗡️💀♻️")
    end

    resp
  end
end

def chaos_template__restarts_on_kill
<<-TEMPLATE
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosEngine
metadata:
  name:  {{ test_name }}
  namespace: default
spec:
  # It can be delete/retain
  jobCleanUpPolicy: 'retain'
  # It can be true/false
  annotationCheck: 'true'
  # It can be active/stop
  engineState: 'active'
  #ex. values: ns1:name=percona,ns2:run=nginx 
  auxiliaryAppInfo: ''
  appinfo: 
    appns: 'default'
    # FYI, To see app label, apply kubectl get pods --show-labels
    applabel: '{{ deployment_label }}={{ deployment_label_value }}'
    appkind: 'deployment'
  chaosServiceAccount: {{ chaos_experiment_name }}-sa 
  experiments:
    - name: {{ chaos_experiment_name }}
      spec:
        components:
          env:
            #Container name where chaos has to be injected              
            - name: TARGET_CONTAINER
              value: '{{ helm_chart_container_name }}' 
            - name: DOCKER_HOST
              value: #{ENV["DOCKER_HOST"]}
            - name: LIB_IMAGE
              value: 'litmuschaos/container-killer:latest'
            - name: LIB
              value: 'containerd'
TEMPLATE
end


