require "colorize"
require "log"

module Kubescape

  #kubescape scan framework nsa --exclude-namespaces kube-system,kube-public
  def self.scan(cmd="framework nsa --exclude-namespaces kube-system,kube-public --format json --output kubescape_results.json")
    alt_cmd = "./tools/kubescape/kubescape scan " + cmd
    Log.info { "command: #{cmd}" }
    status = Process.run(
      alt_cmd,
      shell: true,
      output: output = IO::Memory.new,
      error: stderr = IO::Memory.new
    )
    Log.info { "output: #{output.to_s}" }
    Log.info { "stderr: #{stderr.to_s}" }
    {status: status, output: output.to_s, error: stderr.to_s}
  end

  def self.parse(results_file="kubescape_results.json")
    results_json = File.open(results_file) do |f| 
      JSON.parse(f)
    end
    if results_json["controlReports"]?
        results_json["controlReports"]
    else
      EMPTY_JSON
    end
  end

  def self.result_by_test_name(results_json, test_name)
    resp= results_json.as_a.find {|test|test["name"]==test_name}
    if resp
      resp
    else
      EMPTY_JSON_ARRAY
    end
  end

  def self.score_by_test_name(results_json, test_name)
    test_json = result_by_test_name(results_json, test_name) 
    if test_json && test_json["score"]?
      test_json["score"]
    else
      EMPTY_JSON
    end
  end

  def self.alerts_by_test(test_json)
    if test_json && test_json["ruleReports"]?
      resp = test_json["ruleReports"].as_a.map { |rep|
        rep["ruleResponses"].as_a.map do |res|
          res["alertMessage"]
        end
      }.flatten 
      Log.info {"test_alert resp: #{resp}"}
      resp
    else
      EMPTY_JSON
    end
  end

end
