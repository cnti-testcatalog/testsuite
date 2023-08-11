require "../spec_helper"
require "colorize"
require "../../src/tasks/utils/utils.cr"
require "../../src/tasks/utils/mysql.cr"
require "kubectl_client"
require "helm"
require "file_utils"
require "sam"
require "json"
require "../../src/tasks/utils/operator.cr"

def run_test_with_cleanup(cnf_path : String, &test)
  begin
    LOGGING.info `./cnf-testsuite -l info cnf_setup cnf-path=#{cnf_path}`
    $?.success?.should be_true
    test.call
  ensure
    Operator::OLM.cleanup
    LOGGING.info `./cnf-testsuite -l info cnf_cleanup cnf-path=#{cnf_path}`
    $?.success?.should be_true
  end
end

describe "Operator" do
  describe "pre OLM install" do
    it "'operator_test' operator should not be found", tags: ["operator_test"] do
      run_test_with_cleanup("sample-cnfs/sample_coredns") do
        resp = `./cnf-testsuite -l info operator_installed`
        Log.info { "#{resp}" }
        (/NA: No Operators Found/ =~ resp).should_not be_nil
      end
    end
  end

  describe "OLM" do
   it "install", tags: ["operator_setup"]  do
      Operator::OLM.install
    end

    it "cleans up", tags: ["operator_setup"]  do
      # uninstall OLM
      Operator::OLM.cleanup
    end
  end

  describe "post OLM install" do
    before_all do
      Operator::OLM.install
    end

    after_all do
      # uninstall OLM
      Operator::OLM.cleanup
    end

    it "'operator_test' test if operator is being used", tags: ["operator_test"] do
      run_test_with_cleanup("./sample-cnfs/sample_operator") do
        resp = `./cnf-testsuite -l info operator_installed`
        Log.info { "#{resp}" }
        (/PASSED: Operator is installed/ =~ resp).should_not be_nil
      end
    end

    it "'operator_privileged' test privileged operator NOT being used", tags: ["operator_test"] do
      run_test_with_cleanup("./sample-cnfs/sample_operator") do
        resp = `./cnf-testsuite -l info operator_privileged`
        Log.info { "#{resp}" }
        (/PASSED: Operator is NOT running with privileged rights/ =~ resp).should_not be_nil
      end
    end

    it "'operator_privileged' test if a privileged operator is being used", tags: ["operator_privileged"] do
      run_test_with_cleanup("./sample-cnfs/sample_privileged_operator") do
        resp = `./cnf-testsuite -l info operator_privileged`
        Log.info { "#{resp}" }
        (/FAILED: Operator is running with privileged rights/ =~ resp).should_not be_nil
      end
    end
  end
end
