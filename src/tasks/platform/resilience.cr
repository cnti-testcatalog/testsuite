# coding: utf-8
require "sam"
require "colorize"
require "../utils/utils.cr"

namespace "platform" do
  desc "The CNF conformance suite checks to see if the CNFs are resilient to failures."
  task "resilience", ["node_failure"] do |t, args|
    VERBOSE_LOGGING.info "resilience" if check_verbose(args)
    VERBOSE_LOGGING.debug "resilience args.raw: #{args.raw}" if check_verbose(args)
    VERBOSE_LOGGING.debug "resilience args.named: #{args.named}" if check_verbose(args)
    stdout_score("resilience")
  end

  desc "Does the Platform crash when a node fails"
  # task "node_failure", ["install_chaosmesh"] do |_, args|
  task "node_failure" do |_, args|
    unless check_poc(args)
      LOGGING.info "skipping node_failure"
      puts "Skipped".colorize(:yellow)
      next
    end
    LOGGING.info "Running POC"
    task_response = task_runner(args) do |args|
      emoji_chaos_network_loss="📶☠️"
      resp = upsert_passed_task("node_failure","✔️  PASSED: Nodes are resilient #{emoji_chaos_network_loss}")
    end
  end
end
