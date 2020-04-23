require "sam"
require "./tasks/**"

desc "The CNF Conformance program enables interoperability of CNFs from multiple vendors running on top of Kubernetes supplied by different vendors. The goal is to provide an open source test suite to enable both open and closed source CNFs to demonstrate conformance and implementation of best practices."
task "all", ["results_yml_setup", "compatibility","stateless", "security", "scalability", "configuration_lifecycle", "observability", "installability", "hardware_affinity"] do  |_, args|
  total = total_points
    if total > 0
      puts "Final score: #{total}".colorize(:green)
    else
      puts "Final score: #{total}".colorize(:red)
    end
    new_results = "cnf-conformance-results-" + Time.local.to_s("%Y%m%d-%H%M%S-%L") + ".yml"
    results = `mv #{LOGFILE} #{new_results}`
    puts "Results have been saved to #{new_results}"
end

Sam.help
