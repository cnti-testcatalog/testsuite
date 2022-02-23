require "colorize"
require "log"

module Kubescape

  #kubescape scan framework nsa --exclude-namespaces kube-system,kube-public
  def self.scan(cli : String | Nil = nil)
    if cli == nil
      exclude_namespaces = [
        "kube-system",
        "kube-public",
        "kube-node-lease",
        "local-path-storage",
        "litmus",
        TESTSUITE_NAMESPACE
      ].join(",")
      cli = "framework nsa --use-from ./tools/kubescape/nsa.json --exclude-namespaces #{exclude_namespaces} --format json --output kubescape_results.json"
    end
    cmd = "./tools/kubescape/kubescape scan #{cli}"
    Log.info { "scan command: #{cmd}" }
    status = Process.run(
      cmd,
      shell: true,
      output: output = IO::Memory.new,
      error: stderr = IO::Memory.new
    )
    Log.info { "output: #{output.to_s}" }
    Log.info { "stderr: #{stderr.to_s}" }
    {status: status, output: output.to_s, error: stderr.to_s}
  end

  def self.parse(results_file="kubescape_results.json")
    Log.info { "kubescape parse" }
    results_json = File.open(results_file) do |f| 
      JSON.parse(f)
    end
    if results_json["controlReports"]?
        results_json["controlReports"]
    else
      EMPTY_JSON
    end
  end

  def self.test_by_test_name(results_json, test_name)
    Log.info { "kubescape test_by_test_name" }
    resp= results_json.as_a.find {|test|test["name"]==test_name}
    if resp
      resp
    else
      EMPTY_JSON_ARRAY
    end
  end

  def self.score(test_json)
    if test_json && test_json["score"]?
      test_json["score"]
    else
      EMPTY_JSON
    end
  end

  def self.test_passed?(test_json)
    Log.info { "kubescape test_passed?" }
    score = score(test_json)
    Log.info { "score: #{score}" }
    score.as_i == 100
  end

  def self.score_by_test_name(results_json, test_name)
    test_json = test_by_test_name(results_json, test_name) 
    score(test_json)
  end

  def self.description(test_json)
    if test_json && test_json["description"]?
      test_json["description"]
    else
      EMPTY_JSON
    end
  end

  def self.description_by_test_name(results_json, test_name)
    test_json = test_by_test_name(results_json, test_name) 
    description(test_json)
  end

  def self.remediation(test_json)
    if test_json && test_json["remediation"]?
      test_json["remediation"]
    else
      EMPTY_JSON
    end
  end

  def self.remediation_by_test_name(results_json, test_name)
    test_json = test_by_test_name(results_json, test_name) 
    remediation(test_json)
  end

  def self.alerts_by_test(test_json)
    if test_json && test_json["ruleReports"]?
      resp = test_json["ruleReports"].as_a.map { |rep|
      if rep["ruleResponses"]? && rep["ruleResponses"]? != nil  
        rep["ruleResponses"].as_a.map do |res|
          res["alertMessage"]
        end
      end
      }.flatten.uniq
      Log.info {"test_alert resp: #{resp}"}
      resp
    else
      EMPTY_JSON_ARRAY.as_a
    end
  end

end
