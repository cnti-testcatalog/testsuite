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

end
