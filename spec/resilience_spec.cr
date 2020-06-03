require "./spec_helper"
require "colorize"
require "../src/tasks/utils/utils.cr"
require "../src/tasks/utils/system_information/helm.cr"
require "file_utils"
require "sam"

describe "Resilience" do

  it "'chaos_network_loss' CNF should not crash when network loss occurs", tags: ["chaos_network_loss"]  do
    begin
      `./cnf-conformance cnf_setup cnf-path=sample-cnfs/sample_ping deploy_with_chart=false`
      $?.success?.should be_true
      response_s = `./cnf-conformance chaos_network_loss verbose`
      $?.success?.should be_true
      (/PASSED: Replicas returned to desired count after network chaos test/ =~ response_s).should_not be_nil
    ensure
      `./cnf-conformance cnf_cleanup cnf-path=sample-cnfs/sample_ping deploy_with_chart=false`
      $?.success?.should be_true
    end
  end
end
