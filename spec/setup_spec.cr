require "./spec_helper"
require "colorize"
require "../src/tasks/utils/utils.cr"
require "../src/tasks/utils/system_information/helm.cr"
require "file_utils"
require "sam"

describe "Setup" do
  it "'setup' should completely setup the cnf conformance environment before installing cnfs", tags: "happy-path"  do
    response_s = `./cnf-conformance setup`
    puts response_s
    $?.success?.should be_true
    (/Setup complete/ =~ response_s).should_not be_nil
  end

  it "'cnf_setup/cnf_cleanup' should install/cleanup a cnf with a cnf-conformance.yml", tags: "happy-path"  do
    begin
      #TODO make cnf_setup work with a cnf name based in the cnf-conformance.yml
      #TODO make cnf_setup install a helm directory without having a premade directory located with the cnf-conformance.yml
      response_s = `./cnf-conformance cnf_setup cnf-config=example-cnfs/envoy/cnf-conformance.yml`
      puts response_s
      $?.success?.should be_true
      (/Successfully setup envoy/ =~ response_s).should_not be_nil
    ensure

      response_s = `./cnf-conformance cnf_cleanup cnf-path=example-cnfs/envoy/cnf-conformance.yml`
      puts response_s
      $?.success?.should be_true
      (/Successfully cleaned up/ =~ response_s).should_not be_nil
    end
  end



end
