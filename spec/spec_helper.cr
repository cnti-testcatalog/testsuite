require "spec"
require "colorize"
require "../src/cnf_conformance"

ENV["CRYSTAL_ENV"] = "TEST" 


puts "Building ./cnf-conformance".colorize(:green)
`crystal build src/cnf-conformance.cr`
if $?.success?
  puts "Build Success!".colorize(:green)
else
  puts "crystal build failed!".colorize(:red)
  raise "crystal build failed in spec_helper"
end
