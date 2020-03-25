require "sam"
require "./tasks/**"

desc "The CNF Conformance program enables interoperability of CNFs from multiple vendors running on top of Kubernetes supplied by different vendors. The goal is to provide an open source test suite to enable both open and closed source CNFs to demonstrate conformance and implementation of best practices."
task "all", ["compatibility","stateless", "security", "scalability", "configuration_lifecycle", "observability", "installability", "hardware_affinity"] do  |_, args|
end

Sam.help
