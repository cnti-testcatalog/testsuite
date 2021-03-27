require "./../spec_helper"
require "colorize"
require "./../../src/tasks/utils/utils.cr"

describe "Platform" do
  before_all do
    # LOGGING.debug `pwd` 
    # LOGGING.debug `echo $KUBECONFIG`
    `./cnf-conformance samples_cleanup`
    $?.success?.should be_true
    `./cnf-conformance setup`
    $?.success?.should be_true
  end

  it "'oci_compliant' should pass if all runtimes are oci_compliant", tags: ["platform:oci_compliant"] do
      response_s = `./cnf-conformance platform:oci_compliant`
      LOGGING.info response_s
      (/(PASSED){1}.*(which are OCI compliant runtimes){1}/ =~ response_s).should_not be_nil
  end
end

