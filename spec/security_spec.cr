require "./spec_helper"
require "colorize"
require "../src/tasks/utils/utils.cr"

describe CnfConformance do
  before_all do
    # puts `pwd` 
    # puts `echo $KUBECONFIG`
    `./cnf-conformance samples_cleanup`
    $?.success?.should be_true
    `./cnf-conformance configuration_file_setup`
    # `./cnf-conformance setup`
    # $?.success?.should be_true
  end
  it "'privileged' should pass with a non-privileged cnf", tags: ["privileged", "happy-path"]  do
    begin
      `./cnf-conformance sample_coredns_setup`
      $?.success?.should be_true
      if toggle("multi-cnf") 
        response_s = `./cnf-conformance privileged cnf=sample-coredns-cnf verbose`
      else
        response_s = `./cnf-conformance privileged verbose`
      end
      puts response_s
      $?.success?.should be_true
      (/Found privileged containers.*coredns/ =~ response_s).should be_nil
    ensure
      `./cnf-conformance sample_coredns_cleanup`
    end
  end
  it "'privileged' should fail on a non-whitelisted, privileged cnf", tags: "privileged" do
    begin
      `./cnf-conformance sample_privileged_cnf_non_whitelisted_setup`
      $?.success?.should be_true
      if toggle("multi-cnf") 
        response_s = `./cnf-conformance privileged cnf=sample_privileged_cnf verbose`
      else
        response_s = `./cnf-conformance privileged verbose`
      end
      puts response_s
      $?.success?.should be_true
      (/Found privileged containers.*coredns/ =~ response_s).should_not be_nil
    ensure
      `./cnf-conformance sample_privileged_cnf_non_whitelisted_cleanup`
    end
  end
  it "'privileged' should pass on a whitelisted, privileged cnf", tags: "privileged" do
    begin
      `./cnf-conformance sample_privileged_cnf_whitelisted_setup`
      $?.success?.should be_true
      if toggle("multi-cnf") 
        response_s = `./cnf-conformance privileged cnf=sample_whitelisted_privileged_cnf verbose`
      else
        response_s = `./cnf-conformance privileged verbose`
      end
      puts response_s
      $?.success?.should be_true
      (/Found privileged containers.*coredns/ =~ response_s).should be_nil
    ensure
      `./cnf-conformance sample_privileged_cnf_whitelisted_cleanup`
    end
  end
end
