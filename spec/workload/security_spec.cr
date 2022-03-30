require "../spec_helper"
require "colorize"
require "../../src/tasks/utils/utils.cr"

describe "Security" do

  it "'non_root_user' should pass with a non-root cnf", tags: ["security"]  do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=sample-cnfs/sample_nonroot/cnf-testsuite.yml`
      response_s = `./cnf-testsuite non_root_user verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/Root user not found/ =~ response_s).should_not be_nil
    ensure
      LOGGING.info `./cnf-testsuite cnf_cleanup cnf-config=sample-cnfs/sample_nonroot/cnf-testsuite.yml`
      LOGGING.debug `./cnf-testsuite uninstall_falco`
      KubectlClient::Get.resource_wait_for_uninstall("DaemonSet", "falco")
    end
  end

  it "'non_root_user' should fail with a root cnf", tags: ["security"]  do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=sample-cnfs/k8s-non-helm/cnf-testsuite.yml`
      response_s = `./cnf-testsuite non_root_user verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/Root user found/ =~ response_s).should_not be_nil
    ensure
      LOGGING.info `./cnf-testsuite cnf_cleanup cnf-config=sample-cnfs/k8s-non-helm/cnf-testsuite.yml`
      LOGGING.debug `./cnf-testsuite uninstall_falco`
      KubectlClient::Get.resource_wait_for_uninstall("DaemonSet", "falco")
    end
  end

  it "'privileged' should pass with a non-privileged cnf", tags: ["privileged"]  do
    begin
      LOGGING.debug `./cnf-testsuite cnf_setup cnf-config=sample-cnfs/sample-statefulset-cnf/cnf-testsuite.yml`
      response_s = `./cnf-testsuite privileged verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/Found.*privileged containers.*coredns/ =~ response_s).should be_nil
    ensure
      LOGGING.debug `./cnf-testsuite cnf_cleanup cnf-config=sample-cnfs/sample-statefulset-cnf/cnf-testsuite.yml`
    end
  end
  it "'privileged' should fail on a non-whitelisted, privileged cnf", tags: ["privileged"] do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=./sample-cnfs/sample_privileged_cnf/cnf-testsuite.yml verbose wait_count=0`
      $?.success?.should be_true
      response_s = `./cnf-testsuite privileged verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/Found.*privileged containers.*coredns/ =~ response_s).should_not be_nil
    ensure
      `./cnf-testsuite sample_privileged_cnf_non_whitelisted_cleanup`
    end
  end
  it "'privileged' should pass on a whitelisted, privileged cnf", tags: ["privileged"] do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=./sample-cnfs/sample_whitelisted_privileged_cnf/cnf-testsuite.yml verbose wait_count=0`
      $?.success?.should be_true
      response_s = `./cnf-testsuite privileged cnf-config=sample-cnfs/sample_whitelisted_privileged_cnf verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/Found.*privileged containers.*coredns/ =~ response_s).should be_nil
    ensure
      `./cnf-testsuite sample_privileged_cnf_whitelisted_cleanup`
    end
  end
  it "'privilege_escalation' should fail on a cnf that has escalated privileges", tags: ["privileged"] do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=./sample-cnfs/sample-privilege-escalation/cnf-testsuite.yml`
      $?.success?.should be_true
      response_s = `./cnf-testsuite privilege_escalation`
      LOGGING.info response_s
      $?.success?.should be_true
      (/PASSED: No containers that allow privilege escalation were found/ =~ response_s).should be_nil
    ensure
      `./cnf-testsuite cnf_cleanup cnf-config=./sample-cnfs/sample-privilege-escalation/cnf-testsuite.yml`
    end
  end

  it "'symlink_file_system' should pass on a cnf that does not allow a symlink attack", tags: ["capabilities"] do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=./sample-cnfs/sample-privilege-escalation/cnf-testsuite.yml`
      $?.success?.should be_true
      response_s = `./cnf-testsuite symlink_file_system`
      LOGGING.info response_s
      $?.success?.should be_true
      (/PASSED: No containers allow a symlink attack/ =~ response_s).should_not be_nil
    ensure
      `./cnf-testsuite cnf_cleanup cnf-config=./sample-cnfs/sample-privilege-escalation/cnf-testsuite.yml`
    end
  end

  it "'insecure_capabilities' should pass on a cnf that does not have containers with insecure capabilities", tags: ["capabilities"] do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=./sample-cnfs/sample-coredns-cnf/cnf-testsuite.yml`
      $?.success?.should be_true
      response_s = `./cnf-testsuite insecure_capabilities`
      LOGGING.info response_s
      $?.success?.should be_true
      (/PASSED: Containers with insecure capabilities were not found/ =~ response_s).should_not be_nil
    ensure
      `./cnf-testsuite cnf_cleanup cnf-config=./sample-cnfs/sample-coredns-cnf/cnf-testsuite.yml`
    end
  end

  # it "'insecure_capabilities' should fail on a cnf that has containers with insecure capabilities", tags: ["security"] do
  #   begin
  #     LOGGING.info `./cnf-testsuite cnf_setup cnf-config=./sample-cnfs/sample-insecure-capabilities/cnf-testsuite.yml`
  #     $?.success?.should be_true
  #     response_s = `./cnf-testsuite insecure_capabilities`
  #     LOGGING.info response_s
  #     $?.success?.should be_true
  #     (/PASSED: Containers with insecure capabilities were not found/ =~ response_s).should be_nil
  #   ensure
  #     `./cnf-testsuite cnf_cleanup cnf-config=./sample-cnfs/sample-insecure-capabilities/cnf-testsuite.yml`
  #   end
  # end

  it "'dangerous_capabilities' should pass on a cnf that does not have containers with dangerous capabilities", tags: ["capabilities"] do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=./sample-cnfs/sample-coredns-cnf/cnf-testsuite.yml`
      $?.success?.should be_true
      response_s = `./cnf-testsuite dangerous_capabilities`
      LOGGING.info response_s
      $?.success?.should be_true
      (/PASSED: Containers with dangerous capabilities were not found/ =~ response_s).should_not be_nil
    ensure
      `./cnf-testsuite cnf_cleanup cnf-config=./sample-cnfs/sample-coredns-cnf/cnf-testsuite.yml`
    end
  end

  # it "'dangerous_capabilities' should fail on a cnf that has containers with dangerous capabilities", tags: ["security"] do
  #   begin
  #     LOGGING.info `./cnf-testsuite cnf_setup cnf-config=./sample-cnfs/sample-dangerous-capabilities/cnf-testsuite.yml`
  #     $?.success?.should be_true
  #     response_s = `./cnf-testsuite dangerous_capabilities`
  #     LOGGING.info response_s
  #     $?.success?.should be_true
  #     (/PASSED: Containers with dangerous capabilities were not found/ =~ response_s).should be_nil
  #   ensure
  #     `./cnf-testsuite cnf_cleanup cnf-config=./sample-cnfs/sample-dangerous-capabilities/cnf-testsuite.yml`
  #   end
  # end

  it "'linux_hardening' should fail on a cnf that does not make use of security services", tags: ["capabilities"] do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=./sample-cnfs/sample-coredns-cnf`
      $?.success?.should be_true
      response_s = `./cnf-testsuite linux_hardening`
      LOGGING.info response_s
      $?.success?.should be_true
      (/PASSED: Security services are being used to harden applications/ =~ response_s).should be_nil
    ensure
      `./cnf-testsuite cnf_cleanup cnf-config=./sample-cnfs/sample-coredns-cnf`
    end
  end

  # it "'application_credentials' should fail on a cnf that allows applications credentials in configuration files", tags: ["security"] do
  #   begin
  #     LOGGING.info `./cnf-testsuite cnf_setup cnf-config=./sample-cnfs/sample-privilege-escalation/cnf-testsuite.yml`
  #     $?.success?.should be_true
  #     response_s = `./cnf-testsuite application_credentials`
  #     LOGGING.info response_s
  #     $?.success?.should be_true
  #     (/FAILED: Found applications credentials in configuration files/ =~ response_s).should_not be_nil
  #   ensure
  #     `./cnf-testsuite cnf_cleanup cnf-config=./sample-cnfs/sample-privilege-escalation/cnf-testsuite.yml`
  #   end
  # end

  it "'host_network' should pass on a cnf that does not have a host network attached to pod", tags: ["security"] do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=./sample-cnfs/sample-privilege-escalation/cnf-testsuite.yml`
      $?.success?.should be_true
      response_s = `./cnf-testsuite host_network`
      LOGGING.info response_s
      $?.success?.should be_true
      (/PASSED: No host network attached to pod/ =~ response_s).should_not be_nil
    ensure
      `./cnf-testsuite cnf_cleanup cnf-config=./sample-cnfs/sample-privilege-escalation/cnf-testsuite.yml`
    end
  end

  it "'service_account_mapping' should fail on a cnf that automatically maps the service account", tags: ["security"] do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=./sample-cnfs/sample-privilege-escalation/cnf-testsuite.yml`
      $?.success?.should be_true
      response_s = `./cnf-testsuite service_account_mapping`
      LOGGING.info response_s
      $?.success?.should be_true
      (/FAILED: Service accounts automatically mapped/ =~ response_s).should_not be_nil
    ensure
      `./cnf-testsuite cnf_cleanup cnf-config=./sample-cnfs/sample-privilege-escalation/cnf-testsuite.yml`
    end
  end

  it "'resource_policies' should pass on a cnf that has containers with resource limits defined", tags: ["security"] do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=./sample-cnfs/sample-coredns-cnf`
      $?.success?.should be_true
      response_s = `./cnf-testsuite resource_policies`
      LOGGING.info response_s
      $?.success?.should be_true
      (/PASSED: Containers have resource limits defined/ =~ response_s).should_not be_nil
    ensure
      `./cnf-testsuite cnf_cleanup cnf-config=./sample-cnfs/sample-coredns-cnf`
    end
  end

  it "'ingress_egress_blocked' should fail on a cnf that has no ingress and egress traffic policy", tags: ["security"] do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=./sample-cnfs/sample-coredns-cnf`
      $?.success?.should be_true
      response_s = `./cnf-testsuite ingress_egress_blocked`
      LOGGING.info response_s
      $?.success?.should be_true
      (/PASSED: Ingress and Egress traffic blocked on pods/ =~ response_s).should be_nil
    ensure
      `./cnf-testsuite cnf_cleanup cnf-config=./sample-cnfs/sample-coredns-cnf`
    end
  end

  it "'host_pid_ipc_privileges' should pass on a cnf that does not have containers with host PID/IPC privileges", tags: ["capabilities"] do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=./sample-cnfs/sample-coredns-cnf`
      $?.success?.should be_true
      response_s = `./cnf-testsuite host_pid_ipc_privileges`
      LOGGING.info response_s
      $?.success?.should be_true
      (/FAILED: Found containers with hostPID and hostIPC privileges/ =~ response_s).should be_nil
    ensure
      `./cnf-testsuite cnf_cleanup cnf-config=./sample-cnfs/sample-coredns-cnf`
    end
  end

  it "'non_root_containers' should pass on a cnf that does not have containers running with root user or user with root group memberships", tags: ["security"] do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=./sample-cnfs/sample-coredns-cnf`
      $?.success?.should be_true
      response_s = `./cnf-testsuite non_root_containers`
      LOGGING.info response_s
      $?.success?.should be_true
      (/FAILED: Found containers running with root user or user with root group membership/ =~ response_s).should be_nil
    ensure
      `./cnf-testsuite cnf_cleanup cnf-config=./sample-cnfs/sample-coredns-cnf`
    end
  end

  it "'network_policies' should fail when namespaces do not have network policies defined", tags: ["security"] do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=./sample-cnfs/sample-coredns-cnf`
      $?.success?.should be_true
      response_s = `./cnf-testsuite network_policies`
      LOGGING.info response_s
      $?.success?.should be_true
      (/PASSED: Namespaces have network policies defined/ =~ response_s).should be_nil
    ensure
      `./cnf-testsuite cnf_cleanup cnf-config=./sample-cnfs/sample-coredns-cnf`
    end
  end

  it "'privileged_containers' should pass when the cnf has no privileged containers", tags: ["privileged"] do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=./sample-cnfs/sample-coredns-cnf`
      $?.success?.should be_true
      response_s = `./cnf-testsuite privileged_containers`
      LOGGING.info response_s
      $?.success?.should be_true
      (/FAILED: Found privileged containers/ =~ response_s).should be_nil
    ensure
      `./cnf-testsuite cnf_cleanup cnf-config=./sample-cnfs/sample-coredns-cnf`
    end
  end

  it "'immutable_file_systems' should fail when the cnf containers with mutable file systems", tags: ["security"] do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=./sample-cnfs/sample-coredns-cnf`
      $?.success?.should be_true
      response_s = `./cnf-testsuite immutable_file_systems`
      LOGGING.info response_s
      $?.success?.should be_true
      (/PASSED: Containers have immutable file systems/ =~ response_s).should be_nil
    ensure
      `./cnf-testsuite cnf_cleanup cnf-config=./sample-cnfs/sample-coredns-cnf`
    end
  end

  it "'hostpath_mounts' should pass when the cnf has no containers with hostPath mounts", tags: ["security"] do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=./sample-cnfs/sample-coredns-cnf`
      $?.success?.should be_true
      ClusterTools.uninstall
      response_s = `./cnf-testsuite hostpath_mounts`
      LOGGING.info response_s
      $?.success?.should be_true
      (/FAILED: Found containers with hostPath mounts/ =~ response_s).should be_nil
    ensure
      `./cnf-testsuite cnf_cleanup cnf-config=./sample-cnfs/sample-coredns-cnf`
      ClusterTools.install
    end
  end

  it "'container_sock_mounts' should pass if a cnf has no pods that mount container engine socket", tags: ["container_sock_mounts"] do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=./sample-cnfs/sample_coredns/cnf-testsuite.yml`
      $?.success?.should be_true
      response_s = `./cnf-testsuite container_sock_mounts verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/PASSED: Container engine daemon sockets are not mounted as volumes/ =~ response_s).should_not be_nil
    ensure
      LOGGING.info `./cnf-testsuite cnf_cleanup cnf-config=./sample-cnfs/sample_coredns/cnf-testsuite.yml`
    end
  end

  it "'container_sock_mounts' should fail if the CNF has pods with container engine sockets mounted", tags: ["container_sock_mounts"] do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=./sample-cnfs/sample_container_sock_mount/cnf-testsuite.yml`
      $?.success?.should be_true
      response_s = `./cnf-testsuite container_sock_mounts verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/FAILED: Container engine daemon sockets are mounted as volumes/ =~ response_s).should_not be_nil
      (/Unix socket is not allowed/ =~ response_s).should_not be_nil
    ensure
      LOGGING.info `./cnf-testsuite cnf_cleanup cnf-config=./sample-cnfs/sample_container_sock_mount/cnf-testsuite.yml`
    end
  end

  it "'external_ips' should pass if a cnf has no services with external IPs", tags: ["external_ips"] do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=./sample-cnfs/sample_coredns/cnf-testsuite.yml`
      $?.success?.should be_true
      response_s = `./cnf-testsuite external_ips verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/PASSED: Services are not using external IPs/ =~ response_s).should_not be_nil
    ensure
      LOGGING.info `./cnf-testsuite cnf_cleanup cnf-config=./sample-cnfs/sample_coredns/cnf-testsuite.yml`
    end
  end

  it "'external_ips' should fail if a cnf has services with external IPs", tags: ["external_ips"] do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=./sample-cnfs/sample_external_ips/cnf-testsuite.yml`
      $?.success?.should be_true
      response_s = `./cnf-testsuite external_ips verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/FAILED: Services are using external IPs/ =~ response_s).should_not be_nil
    ensure
      LOGGING.info `./cnf-testsuite cnf_cleanup cnf-config=./sample-cnfs/sample_external_ips/cnf-testsuite.yml`
    end
  end

  it "'selinux_options' should fail if containers have custom selinux options that can be used for privilege escalations", tags: ["selinux_options"] do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=./sample-cnfs/sample_latest_tag`
      $?.success?.should be_true
      response_s = `./cnf-testsuite selinux_options verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/FAILED: Resources are using custom SELinux options/ =~ response_s).should_not be_nil
    ensure
      LOGGING.info `./cnf-testsuite cnf_cleanup cnf-config=./sample-cnfs/sample_latest_tag`
    end
  end

  it "'selinux_options' should pass if containers do not have custom selinux options that can be used for privilege escalations", tags: ["selinux_options"] do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=./sample-cnfs/sample_nonroot`
      $?.success?.should be_true
      response_s = `./cnf-testsuite selinux_options verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/PASSED: Resources are not using custom SELinux options/ =~ response_s).should_not be_nil
    ensure
      LOGGING.info `./cnf-testsuite cnf_cleanup cnf-config=./sample-cnfs/sample_nonroot`
    end
  end

  it "'sysctls' should fail if Pods have restricted sysctls values", tags: ["sysctls"] do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=./sample-cnfs/sample_latest_tag`
      $?.success?.should be_true
      response_s = `./cnf-testsuite sysctls verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/FAILED: Restricted values for are being used for sysctls/ =~ response_s).should_not be_nil
    ensure
      LOGGING.info `./cnf-testsuite cnf_cleanup cnf-config=./sample-cnfs/sample_latest_tag`
    end
  end

  it "'sysctls' should pass if Pods have allowed sysctls values", tags: ["sysctls"] do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=./sample-cnfs/sample_nonroot`
      $?.success?.should be_true
      response_s = `./cnf-testsuite sysctls verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/PASSED: No restricted values found for sysctls/ =~ response_s).should_not be_nil
    ensure
      LOGGING.info `./cnf-testsuite cnf_cleanup cnf-config=./sample-cnfs/sample_nonroot`
    end
  end
end
