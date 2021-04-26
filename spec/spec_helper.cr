require "spec"
require "colorize"
require "../src/cnf_conformance"

ENV["CRYSTAL_ENV"] = "TEST" 


LOGGING.info "Building ./cnf-testsuite".colorize(:green)
`crystal build --warnings none src/cnf-conformance.cr`
`mv ./cnf-conformance ./cnf-testsuite`
if $?.success?
  LOGGING.info "Build Success!".colorize(:green)
else
  LOGGING.info "crystal build failed!".colorize(:red)
  raise "crystal build failed in spec_helper"
end
