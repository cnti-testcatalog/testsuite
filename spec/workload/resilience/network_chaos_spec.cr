require "../../spec_helper"
require "colorize"
require "../../../src/tasks/utils/utils.cr"
require "../../../src/tasks/utils/system_information/helm.cr"
require "file_utils"
require "sam"

describe "Resilience Network Chaos" do
  before_all do
    `./cnf-conformance setup`
    `./cnf-conformance configuration_file_setup`
    $?.success?.should be_true
  end

  it "'chaos_network_loss' A 'Good' CNF should not crash when network loss occurs", tags: ["chaos_network_loss"]  do
    begin
      `./cnf-conformance cnf_setup cnf-config=sample-cnfs/sample-coredns-cnf/cnf-conformance.yml`
      $?.success?.should be_true
      response_s = `./cnf-conformance chaos_network_loss verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/PASSED: Replicas available match desired count after network chaos test/ =~ response_s).should_not be_nil
    ensure
      `./cnf-conformance cnf_cleanup cnf-config=sample-cnfs/sample-coredns-cnf/cnf-conformance.yml`
      $?.success?.should be_true
    end
  end

  it "'chaos_network_loss' A 'Bad' CNF should crash when network loss occurs", tags: ["chaos_network_loss"]  do
    begin
      `./cnf-conformance cnf_setup cnf-path=sample-cnfs/sample_network_loss deploy_with_chart=false`
      $?.success?.should be_true
      response_s = `./cnf-conformance chaos_network_loss verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/FAILURE: Replicas did not return desired count after network chaos test/ =~ response_s).should_not be_nil
    ensure
      `./cnf-conformance cnf_cleanup cnf-path=sample-cnfs/sample_network_loss deploy_with_chart=false`
      $?.success?.should be_true
    end
  end
end
