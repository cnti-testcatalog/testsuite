require "./spec_helper"
require "colorize"
require "../src/tasks/utils/utils.cr"
require "../src/tasks/utils/system_information/helm.cr"
require "file_utils"
require "sam"

describe "Prereq" do
  it "'prereq' should check the system for prerequisites", tags: "happy-path"  do
    response_s = `./cnf-conformance prereqs verbose`
    puts response_s
    $?.success?.should be_true
    (/helm found/ =~ response_s).should_not be_nil
    (/wget found/ =~ response_s).should_not be_nil
    (/curl found/ =~ response_s).should_not be_nil
    (/kubectl found/ =~ response_s).should_not be_nil
  end

end
