require "spec"
require "colorize"
require "../src/cnf_conformance"

ENV["CRYSTAL_ENV"] = "TEST" 

`crystal build src/cnf-conformance.cr`
if $?.success? == false 
  puts "crystal build failed!".colorize(:red)
end
