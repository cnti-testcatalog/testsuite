# coding: utf-8
require "sam"
require "file_utils"
require "colorize"
require "totem"
require "../utils/utils.cr"

desc "The CNF Test Suite program certifies a CNF based on passing some percentage of essential tests."
task "cert", ["cert_compatibility", "cert_state", "cert_security", "cert_configuration", "cert_observability", "cert_microservice", "cert_resilience", "latest_tag", "selinux_options", "single_process_type", "node_drain","liveness", "readiness", "log_output", "container_sock_mounts", "privileged_containers", "non_root_containers", "resource_policies", "hostport_not_used", "hardcoded_ip_addresses_in_k8s_runtime_configuration"] do  |_, args|
  VERBOSE_LOGGING.info "cert" if check_verbose(args)

  stdout_success "RESULTS SUMMARY"
  total = CNFManager::Points.total_points()
  max_points = CNFManager::Points.total_max_points()
  total_passed = CNFManager::Points.total_passed()
  max_passed = CNFManager::Points.total_max_passed()
  essential_total_passed = CNFManager::Points.total_passed("cert")
  essential_max_passed = CNFManager::Points.total_max_passed("cert")
  stdout_success "  - #{total_passed} of #{max_passed} total tests passed"
  if total >= 1000 
    stdout_success "  - #{essential_total_passed} of #{essential_max_passed} essential tests passed"
  else
    stdout_failure "FAILED: #{essential_total_passed} of #{essential_max_passed} essential tests passed"
  end

  update_yml("#{CNFManager::Points::Results.file}", "points", total)
  update_yml("#{CNFManager::Points::Results.file}", "maximum_points", max_points)

  if CNFManager::Points.failed_required_tasks.size > 0
    stdout_failure "Test Suite failed!"
    stdout_failure "Failed required tasks: #{CNFManager::Points.failed_required_tasks.inspect}"
    yaml = File.open("#{CNFManager::Points::Results.file}") do |file|
      YAML.parse(file)
    end
    Log.debug { "results yaml: #{yaml}" }
    if (yaml["exit_code"]) != 2
      update_yml("#{CNFManager::Points::Results.file}", "exit_code", "1")
    end
  end
  stdout_info "Results have been saved to #{CNFManager::Points::Results.file}".colorize(:green)
end

