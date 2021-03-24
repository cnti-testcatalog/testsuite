# coding: utf-8
require "./spec_helper"
require "colorize"
require "../src/tasks/utils/utils.cr"
require "file_utils"
require "sam"

describe "CurlInstall" do
  after_all do
    LOGGING.info "Curl install tests finished.  Building ./cnf-conformance again".colorize(:green)
    `crystal build src/cnf-conformance.cr`
    if $?.success?
      LOGGING.info "Build Success!".colorize(:green)
    else
      LOGGING.info "crystal build failed!".colorize(:red)
      raise "crystal build failed in spec_helper"
    end
  end
  it "'source curl_install.sh' should download a cnf-conformance binary", tags: ["curl"]  do
    response_s = `/bin/bash -c "source ./curl_install.sh"`
    LOGGING.info response_s
    (/cnf-conformance/ =~ response_s).should_not be_nil
  end
  it "'curl_install.sh' should download a cnf-conformance binary", tags: ["curl"]  do
    response_s = `./curl_install.sh`
    LOGGING.info response_s
    (/To use cnf-conformance please restart you terminal session to load the new 'path'/ =~ response_s).should_not be_nil
  end
end
