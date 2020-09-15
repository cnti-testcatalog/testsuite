require "./../spec_helper"
require "colorize"
require "./../../src/tasks/utils/utils.cr"

describe "Observability" do
  before_all do
    # LOGGING.debug `pwd` 
    # LOGGING.debug `echo $KUBECONFIG`
    # `./cnf-conformance samples_cleanup`
    # $?.success?.should be_true
    # `./cnf-conformance setup`
    # $?.success?.should be_true
  end

  it "'kube_state_metrics' should return some json", tags: "platform:kube_state_metrics" do
      response_s = `./cnf-conformance platform:kube_state_metrics poc`
      LOGGING.info response_s
      # (/(PASSED){1}.*(which are OCI compliant runtimes){1}/ =~ response_s).should_not be_nil
      (/(PASSED){1}.*(Your platform is using the){1}.*(release for kube state metrics){1}/ =~ response_s).should_not be_nil
  end

end

