require "totem"
require "colorize"
require "./cnf_manager.cr"
require "halite"


module K8sInstrumentation
  def self.disk_speed
    pod_status = KubectlClient::Get.pod_status("cluster-tools", namespace: TESTSUITE_NAMESPACE)
    cluster_tools = pod_status.split(",")[0]
    Log.info { "k8s_instrumentation_debug Pod status: #{pod_status.inspect}" }
    result = ShellCmd.run("kubectl get all -A", "k8s_instrumentation_debug", force_output: true)
    resp = KubectlClient.exec("#{cluster_tools} -ti -- /bin/bash -c 'sysbench fileio prepare && sysbench fileio --file-test-mode=rndrw run'", namespace: TESTSUITE_NAMESPACE)
    parse_sysbench(resp[:output].to_s)
  end

  def self.parse_sysbench(sysbench_output)
    parsed_output = sysbench_output.split("\n").reduce(Hash(String, String).new) do |acc,x| 
      if (x.match(/(.*):(.*)/).try &.[1])
        acc.merge({"#{(x.match(/(.*):(.*)/).try &.[1])}".strip => "#{x.match(/(.*):(.*)/).try &.[2]}".strip})
      else
        acc
      end
    end
    Log.debug { "parsed_output: #{parsed_output}" }
    parsed_output
  end
end
