require "../spec_helper"
require "../../src/tasks/utils/airgap.cr"
require "../../src/tasks/utils/kubectl_client.cr"
require "../../src/tasks/utils/k8s_instrumentation.cr"
require "file_utils"
require "sam"

describe "K8sInstrumentation" do


  it "'#disk_speed' should return all responses for the sysbench disk speed call on a pod", tags: ["k8s-instrumentation"]  do
    LOGGING.info `./cnf-testsuite install_cri_tools`
    resp = K8sInstrumentation.disk_speed
    (resp["95th percentile"]).should_not be_nil
    (resp["95th percentile"].to_f).should_not be_nil
  end


end

