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
# task "restarts_on_kill", ["install_litmus", "retrieve_manifest"] do |_, args|
task "restarts_on_kill", ["retrieve_manifest"] do |_, args|
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

    errors = 0
    begin
      deployment_label_value = deployment.get("metadata").as_h["labels"].as_h[deployment_label].as_s
    rescue ex
      errors = errors + 1
      puts ex.message 
    end
    if errors < 1
      template = Crinja.render(chaos_template__restarts_on_kill, { 
        "test_name" => "conformance-container-kill" , "helm_chart_container_name" => "#{helm_chart_container_name}", "deployment_label" => "#{deployment_label}" , "deployment_label_value" => "#{deployment_label_value}" 
      })
      chaos_config = `echo "#{template}" > "#{destination_cnf_dir}/container-kill-chaosengine.yml"`
      puts "#{chaos_config}" if check_verbose(args)
      run_chaos = `kubectl create -f "#{destination_cnf_dir}/container-kill-chaosengine.yml"`
      puts "#{run_chaos}" if check_verbose(args)
    else
      resp = upsert_failed_task("restarts_on_kill","✖️  FAILURE: No deployment label found for container kill test")
    end
    
    describe_chaos_result = "kubectl describe chaosresults.litmuschaos.io"
    puts "initial checkin of #{describe_chaos_result}" if check_verbose(args)  
    puts `#{describe_chaos_result}` if check_verbose(args)  

    verdict = `kubectl get chaosresults.litmuschaos.io conformance-container-kill -o jsonpath='{.status.experimentstatus.verdict}'` 

    until verdict
      verdict = `kubectl get chaosresults.litmuschaos.io conformance-container-kill -o jsonpath='{.status.experimentstatus.verdict}'` 
      puts verdict if check_verbose(args)  
    end

    puts `#{describe_chaos_result}` if check_verbose(args)  

    if verdict == "Pass"
      resp = upsert_passed_task("restarts_on_kill","✔️  PASSED: container-kill chaos test passed 🗡️💀♻️")
    else
      resp = upsert_failed_task("restarts_on_kill","✖️  FAILURE: container-kill chaos test failed 🗡️💀♻️")
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
  jobCleanUpPolicy: 'delete'
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
  chaosServiceAccount: container-kill-sa 
  experiments:
    - name: container-kill
      spec:
        components:
          env:
            #Container name where chaos has to be injected              
            - name: TARGET_CONTAINER
              value: '{{ helm_chart_container_name }}' 
TEMPLATE
end


