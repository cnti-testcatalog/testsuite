require "./spec_helper"
require "colorize"

describe CnfConformance do
 # TODO: Write tests
  before_all do
    # puts `pwd` 
    # puts `echo $KUBECONFIG`
    `crystal src/cnf-conformance.cr cleanup`
    $?.success?.should be_true
    `crystal src/cnf-conformance.cr setup`
    $?.success?.should be_true

  end
  it "'all' should run the whole test suite" do
    response = String::Builder.new
    # Note, output only works with verbose
    Process.run("crystal src/cnf-conformance.cr all verbose", shell: true) do |proc|
      while line = proc.output.gets
        response << line
        # puts "#{line}"
      end
    end

    $?.success?.should be_true
    response_s = response.to_s
    (/PASSED: Helm readiness probe found/ =~ response_s).should_not be_nil
    (/PASSED: Helm liveness probe/ =~ response_s).should_not be_nil
    (/FAILURE: Helm not found in install script/ =~ response_s).should_not be_nil
    (/FAILURE: IP addresses found/ =~ response_s).should_not be_nil
    (/Lint Passed/ =~ response_s).should_not be_nil
    ((/PASSED: No privileged containers/ =~ response_s) || (/Found privileged containers/ =~ response_s)).should_not be_nil
  end
end
