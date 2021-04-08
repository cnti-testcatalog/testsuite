# Conformance Test Categories
The CNF Conformance program validates interoperability of CNF **workloads** supplied by multiple different vendors orchestrated by Kubernetes **platforms** that are supplied by multiple different vendors. The goal is to provide an open source test suite to enable both open and closed source CNFs to demonstrate conformance and implementation of best practices.  For more detailed CLI documentation see the [usage document.](https://github.com/cncf/cnf-conformance/blob/main/USAGE.md)

## Compatability Tests 
#### CNFs should work with any Certified Kubernetes product and any CNI-compatible network that meet their functionality requirements.  The CNF Conformance Suite validates this:
#### On platforms:
*  Performing CNI Plugin testing which:
    * Tests if CNI Plugin follows the [CNI specification](https://github.com/containernetworking/cni/blob/master/SPEC.md)
#### On workloads:
*  Performing K8s API usage testing by running [API snoop](https://github.com/cncf/apisnoop) on the cluster which:
    * Checks alpha endpoint usage
    * Checks beta endpoint usage
    * Checks generally available (GA) endpoint usage

## Statelessness Tests 
#### The CNF conformance suite checks if state is stored in a [custom resource definition](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/) or a separate database (e.g. [etcd](https://github.com/etcd-io/etcd)) rather than requiring local storage.  It also checks to see if state is resilient to node failure:
#### On workloads:
*  Resetting the container and checking to see if the CNF comes back up
*  Using upstream projects for chaos engineering (e.g [Litmus](https://github.com/litmuschaos/litmus))

## Security Tests 
#### CNF containers should be isolated from one another and the host.  The CNF Conformance suite uses tools like [OPA Gatekeeper](https://github.com/open-policy-agent/gatekeeper), [Falco](https://github.com/falcosecurity/falco), [Sysdig Inspect](https://github.com/draios/sysdig-inspect) and [gVisor](https://github.com/google/gvisor):
#### On platforms:
*  Check if there are any shells
#### On workloads:
*  Check if any containers are running in privileged mode
*  Check if any protected directories or files are accessed

## Microservice Tests 
#### The CNF should be developed and delivered as a microservice. The CNF Conformance suite tests to determine the organizational structure and rate of change of the CNF being tested. Once these are known we can detemine whether or not the CNF is a microservice. See: [Microservice-Principles](https://networking.cloud-native-principles.org/cloud-native-microservice-principles):
#### On workloads:
*  Check if the CNF have a reasonable startup time.
*  Check the image size of the CNF.

## Scalability Tests  
#### The CNF conformance suite checks to see if CNFs support horizontal scaling (across multiple machines) and vertical scaling (between sizes of machines) by using the native K8s [kubectl](https://kubernetes.io/docs/reference/kubectl/cheatsheet/#scaling-resources):
#### On workloads:
*  Test increasing/decreasing capacity
*  Test small scale autoscaling with kubectl
*  Test large scale autoscaling with load test tools like [CNF Testbed](https://github.com/cncf/cnf-testbed)
*  Test if the CNF control layer responds to retries for failed communication (e.g. using [Pumba](https://github.com/alexei-led/pumba) or [Blockade](https://github.com/worstcase/blockade) for network chaos and [Envoy](https://github.com/envoyproxy/envoy) for retries)

(see [scalability test usage documentation](https://github.com/cncf/cnf-conformance/blob/main/USAGE.md#scaling-tests))

## Configuration and Lifecycle Tests 
#### Configuration and lifecycle should be managed in a declarative manner, using [ConfigMaps](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/), [Operators](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/), or other [declarative interfaces](https://kubernetes.io/docs/concepts/overview/working-with-objects/kubernetes-objects/#understanding-kubernetes-objects).  The Conformance suite checks this by:
#### On workloads:
*  Testing if the CNF is installed using a [versioned](https://helm.sh/docs/topics/chart_best_practices/dependencies/#versions) Helm v3 chart
*  Searching for hardcoded IP addresses, subnets, or node ports in the configuration
*  Checking for a liveness entry in the helm chart and if the container is responsive to it after a reset (e.g. by checking the [helm chart entry](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/))
*  Checking for a readiness entry in the helm chart and if the container is responsive to it after a reset
*  Checking if the pod/container can be started without mounting a volume (e.g. using [helm configuration](https://kubernetes.io/docs/tasks/configure-pod-container/configure-volume-storage/)) that has configuration files
*  Testing to see if we can start pods/containers and see that the application continues to perform (e.g. using [Litmus](https://github.com/litmuschaos/litmus))
*  Testing by reseting any child processes, and when the parent process is started, checking to see if those child processes are reaped (ie. monitoring processes with [Falco](https://github.com/falcosecurity/falco) or [sysdig-inspect](https://github.com/draios/sysdig-inspect))
*  Testing if the CNF can perform a rolling update (also rolling downgrade) (i.e. [kubectl rolling update](https://kubernetes.io/docs/tasks/run-application/rolling-update-replication-controller/))
*  Testing if the CNF can perform a rollback (i.e. [kubectl_rollout_undo](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#rolling-back-to-a-previous-revision))
*  Testing if there are any (non-declarative) hardcoded IP addresses or subnet masks 

## Observability Tests 
#### In order to maintain, debug, and have insight into a protected environment, its infrastructure elements must have the property of being observable. This means these elements must externalize their internal states in some way that lends itself to metrics, tracing, and logging. The Conformance suite checks this:
#### On workloads:
*  Testing to see if there is traffic to [Fluentd](https://github.com/fluent/fluentd)
*  Testing to see if there is traffic to [Jaeger](https://github.com/jaegertracing/jaeger)
*  Testing to see if Prometheus rules for the CNF are configured correctly (e.g. using [Promtool](https://prometheus.io/docs/prometheus/latest/configuration/unit_testing_rules/))
*  Testing to see if there is traffic to [Prometheus](https://github.com/prometheus/prometheus)
*  Testing to see if the tracing calls are compatible with [OpenTelemetry](https://opentracing.io/) 
*  Testing to see if the monitoring calls are compatible with [OpenMetric](https://github.com/OpenObservability/OpenMetrics) 
#### On platforms:
*  Testing to see if there is an [OpenTelemetry](https://opentracing.io/) compatible service installed
*  Testing to see if there is an [OpenMetric](https://github.com/OpenObservability/OpenMetrics) compatible service installed


## Installable and Upgradeable Tests
#### The CNF Conformance suite will check for usage of standard, in-band deployment tools such as Helm (version 3) charts. The Conformance suite checks this:
#### On workloads:
*  Testing if the install script uses [Helm v3](https://github.com/helm/)
*  Testing if the CNF is published to a public helm chart repository.
*  Testing if the Helm chart is valid (e.g. using the [helm linter](https://github.com/helm/chart-testing))
*  Testing if the CNF can perform a rolling update (i.e. [kubectl rolling update](https://kubernetes.io/docs/tasks/run-application/rolling-update-replication-controller/))

## Hardware Resources and Scheduling Tests 
#### The CNF container should access all hardware and schedule to specific worker nodes by using a device plugin.  The CNF Conformance suite checks this:
#### On platforms:
*  Testing if the Platform supplies an OCI compatible runtime
*  Testing if the Platform supplies an CRI compatible runtime
#### On workloads:
*  Checking if the CNF is accessing hardware in its configuration files
*  Testing if the CNF accessess hardware directly during run-time (e.g. accessing the host /dev or /proc from a mount)
*  Testing if the CNF accessess hugepages directly instead of via [Kubernetes resources](https://github.com/cncf/cnf-testbed/blob/c4458634deca5e8ab73adf118eedde32904c8458/examples/use_case/external-packet-filtering-on-k8s-nsm-on-packet/gateway.yaml#L29)
*  Testing if the CNF Testbed performance output shows adequate throughput and sessions using the [CNF Testbed](https://github.com/cncf/cnf-testbed) (vendor neutral) hardware environment.

## Resilience Tests 
[Cloud Native Definition](https://github.com/cncf/toc/blob/master/DEFINITION.md) requires systems to be Resilient to failures inevitable in cloud environments. CNF Resilience should be tested to ensure CNFs are designed to deal with non-carrier-grade shared cloud HW/SW platform:
#### On platforms:
* Test for full failures in SW and HW platform: stopped cloud infrastructure/platform services, workload microservices or HW ingredients and nodes
* Test for bursty, regular or partial impairments on key dependencies: CPU cycles by pausing, limiting or overloading; DPDK-based Dataplane networking by dropping and/or delaying packets.
* Test if the CNF crashes when network loss occurs (Network Chaos)

Tools to study/use for such testing methodology: The previously mentioned Pumba and Blocade,  [ChaosMesh](https://github.com/pingcap/chaos-mesh), [Mitmproxy](https://github.com/mitmproxy/mitmproxy/), Istio for "[Network Resilience](https://istio.io/docs/concepts/traffic-management/#network-resilience-and-testing)", kill -STOP -CONT, [LimitCPU](http://limitcpu.sourceforge.net/), [Packet pROcessing eXecution (PROX) engine](https://wiki.opnfv.org/pages/viewpage.action?pageId=12387840) as [Impair Gateway](https://github.com/opnfv/samplevnf/blob/master/VNFs/DPPD-PROX/helper-scripts/rapid/impair.cfg).
