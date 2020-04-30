require "./spec_helper"
require "colorize"
require "../src/tasks/utils/utils.cr"
require "../src/tasks/utils/system_information/helm.cr"
require "file_utils"
require "sam"

describe "Microservice" do
  it "'image_size_large' should check the cnf for microservice principles" do
    # response_s = `crystal src/cnf-conformance.cr image_size_large verbose`
    # puts response_s
    # $?.success?.should be_true
    # (/Image size is good/ =~ response_s).should_not be_nil
  end

end
