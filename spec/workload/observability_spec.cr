require "../spec_helper"
require "colorize"
require "../../src/tasks/utils/utils.cr"

describe "Observability" do
  it "'log_output' should pass with a cnf that outputs logs to stdout", tags: ["observability"]  do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=sample-cnfs/sample-coredns-cnf/cnf-testsuite.yml`
      response_s = `./cnf-testsuite log_output verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/PASSED: Resources output logs to stdout and stderr/ =~ response_s).should_not be_nil
    ensure
      LOGGING.info `./cnf-testsuite cnf_cleanup cnf-config=sample-cnfs/sample-coredns-cnf/cnf-testsuite.yml`
    end
  end

  it "'log_output' should fail with a cnf that does not output logs to stdout", tags: ["observability"]  do
    begin
      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=sample-cnfs/sample_no_logs/cnf-testsuite.yml`
      response_s = `./cnf-testsuite log_output verbose`
      LOGGING.info response_s
      $?.success?.should be_true
      (/FAILED: Resources do not output logs to stdout and stderr/ =~ response_s).should_not be_nil
    ensure
      LOGGING.info `./cnf-testsuite cnf_cleanup cnf-config=sample-cnfs/sample_no_logs/cnf-testsuite.yml`
    end
  end

  it "'prometheus_traffic' should pass if there is prometheus traffic", tags: ["observability"] do

      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=sample-cnfs/sample-prometheus-coredns/cnf-testsuite.yml`
      LOGGING.info "Installing prometheus server" 
      helm = BinarySingleton.helm
      resp = `#{helm} install prometheus prometheus-community/prometheus`
      LOGGING.info resp
      KubectlClient::Get.wait_for_install("prometheus-server")

      response_s = `./cnf-testsuite prometheus_traffic`
      LOGGING.info response_s
      (/PASSED: Your cnf is sending prometheus traffic/ =~ response_s).should_not be_nil
  ensure
      LOGGING.info `./cnf-testsuite cnf_cleanup cnf-config=sample-cnfs/sample-prometheus-coredns/cnf-testsuite.yml`
      resp = `#{helm} delete prometheus`
      LOGGING.info resp
      $?.success?.should be_true
  end

  it "'prometheus_traffic' should skip if there is no prometheus installed", tags: ["observability"] do

      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=sample-cnfs/sample-coredns-cnf/cnf-testsuite.yml`
      helm = BinarySingleton.helm
      resp = `#{helm} delete prometheus`
      LOGGING.info resp

      response_s = `./cnf-testsuite prometheus_traffic`
      LOGGING.info response_s
      (/SKIPPED: Prometheus server not found/ =~ response_s).should_not be_nil
    ensure
      LOGGING.info `./cnf-testsuite cnf_cleanup cnf-config=sample-cnfs/sample-coredns-cnf/cnf-testsuite.yml`
  end

  it "'prometheus_traffic' should fail if there is no prometheus installed", tags: ["observability"] do

      LOGGING.info `./cnf-testsuite cnf_setup cnf-config=sample-cnfs/sample-coredns-cnf/cnf-testsuite.yml`
      LOGGING.info "Installing prometheus server" 
      helm = BinarySingleton.helm
      resp = `#{helm} install prometheus prometheus-community/prometheus`
      LOGGING.info resp
      KubectlClient::Get.wait_for_install("prometheus-server")

      response_s = `./cnf-testsuite prometheus_traffic`
      LOGGING.info response_s
      (/FAILED: Your cnf is not sending prometheus traffic/ =~ response_s).should_not be_nil
  ensure
      LOGGING.info `./cnf-testsuite cnf_cleanup cnf-config=sample-cnfs/sample-coredns-cnf/cnf-testsuite.yml`
      resp = `#{helm} delete prometheus`
      LOGGING.info resp
      $?.success?.should be_true
  end
end
