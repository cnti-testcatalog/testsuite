require "../spec_helper"
require "../../src/tasks/utils/airgap.cr"
require "../../src/tasks/utils/kubectl_client.cr"
require "../../src/tasks/utils/kernel_instrospection.cr"
require "file_utils"
require "sam"

describe "KernelInstrospection" do


  it "'#status_by_proc' should return all statuses for all containers in a pod", tags: ["kernel-introspection"]  do
    AirGap.bootstrap_cluster()
    # KubectlClient::Apply.file("./tools/cri-tools/manifest.yml")
    pods = KubectlClient::Get.pods_by_nodes(KubectlClient::Get.schedulable_nodes_list)
    (pods).should_not be_nil
    pods = KubectlClient::Get.pods_by_label(pods, "name", "cri-tools")
    LOGGING.info "pods: #{pods}"
    (pods).should_not be_nil
    if pods && pods[0]? != Nil
      (pods.size).should be > 0
      first_node = pods[0]
      if first_node
        statuses = KernelIntrospection::K8s.status_by_proc(first_node.dig("metadata", "name"), "cri-tools")
        LOGGING.info "statuses: #{statuses}"
        (statuses).should_not be_nil
        (statuses[0]["Pid"]).should eq "1"
        (statuses[0]["cmdline"]).should eq "sleep\u0000infinity\u0000"
      else 
        true.should be_false
      end
    else
      true.should be_false
    end
  end


end

