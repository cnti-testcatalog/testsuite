require "colorize"
require "log"

module Kubescape

  #kubescape scan framework nsa --exclude-namespaces kube-system,kube-public
  def self.scan(cli : String | Nil = nil)
    if cli == nil
      exclude_namespaces = EXCLUDE_NAMESPACES.join(",")
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
    puts "...TEST JSON"
    puts test_json.as_h.keys

    if test_json && test_json["ruleReports"]?
      resp = test_json["ruleReports"].as_a.map { |rep|
      if rep["ruleResponses"]? && rep["ruleResponses"]? != nil  
        puts "...RULE REPORT"
        puts rep.as_h.keys
        puts rep["remediation"]
        rep["ruleResponses"].as_a.map do |res|
          puts "...RULE RESPONSE"
          puts res.as_h.keys
          puts res["alertMessage"]
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

  def self.parse_test_report(test_json)
    test_json = test_json.as_h
    test_resources = [] of TestResource

    test_json["ruleReports"].as_a.map do |rule_report|
      rule_name = rule_report["name"].as_s
      rule_report.as_h["ruleResponses"].as_a.map do |rule_response|
        alert_message = rule_response.dig?("alertMessage")
        k8s_objects = rule_response.dig("alertObject", "k8sApiObjects")
        if k8s_objects == nil
          nil
        else
          k8s_objects.as_a.map do |k8s_obj|
            test_resource = TestResource.new(
              rule_name: rule_name,
              kind: k8s_obj["kind"].as_s,
              name: k8s_obj.dig("metadata", "name").as_s,
              namespace: k8s_obj.dig("metadata", "namespace").as_s,
              alert_message: alert_message ? alert_message.as_s : alert_message
            )
            test_resources << test_resource
          end
        end
      end
    end

    remediation = test_json.dig?("remediation")
    test_report = TestReport.new(
      name: test_json.dig("name").as_s,
      remediation: remediation ? remediation.as_s : remediation,
      failed_resources: test_resources
    )
    test_report
  end

  def self.filter_cnf_resources(test_report : TestReport, resource_keys : Array(String)) : TestReport
    failed_resources = test_report.failed_resources.select do |resource|
      CNFManager.resources_includes?(resource_keys, resource.kind, resource.name, resource.namespace)
    end
    test_report.failed_resources = failed_resources
    test_report
  end

  struct TestReport
    property name
    property remediation
    property failed_resources

    def initialize(@name : String, @remediation : String | Nil, @failed_resources : Array(TestResource))
    end
  end

  struct TestResource
    property rule_name
    property kind
    property name
    property namespace
    property alert_message

    def initialize(@rule_name : String, @kind : String, @name : String, @namespace : String, @alert_message : String | Nil)
    end
  end

end
