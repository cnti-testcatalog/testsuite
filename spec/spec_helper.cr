require "spec"
require "colorize"
require "../src/cnf_conformance"

ENV["CRYSTAL_ENV"] = "TEST" 


LOGGING.info "Building ./cnf-conformance".colorize(:green)
`crystal build src/cnf-conformance.cr`
if $?.success?
  LOGGING.info "Build Success!".colorize(:green)
else
  LOGGING.info "crystal build failed!".colorize(:red)
  raise "crystal build failed in spec_helper"
end
