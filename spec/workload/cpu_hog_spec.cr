require "../spec_helper"
require "colorize"
require "../../src/tasks/utils/utils.cr"
require "../../src/tasks/utils/system_information/helm.cr"
require "file_utils"
require "sam"

describe "CPU_ho" do
  before_all do
    `./cnf-conformance configuration_file_setup`
    $?.success?.should be_true
  end

  it "'chaos_cpu_hog' A 'Good' CNF should not crash at 100% cpu usage", tags: ["chaos_cpu_hog"]  do
    begin
      `./cnf-conformance cnf_setup cnf-config=sample-cnfs/sample-coredns-cnf/cnf-conformance.yml`
      $?.success?.should be_true
      response_s = `./cnf-conformance chaos_cpu_hog verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/PASSED: Application pod is healthy after high CPU consumption/ =~ response_s).should_not be_nil
    ensure
      `./cnf-conformance cnf_cleanup cnf-config=sample-cnfs/sample-coredns-cnf/cnf-conformance.yml`
      $?.success?.should be_true
    end
  end
end
