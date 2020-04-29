# Conformance Test Categories
The CNF Conformance program enables interoperability of CNFs from multiple vendors running on top of Kubernetes supplied by different vendors. The goal is to provide an open source test suite to enable both open and closed source CNFs to demonstrate conformance and implementation of best practices.  For more detailed CLI documentation see the [usage document.](https://github.com/cncf/cnf-conformance/blob/master/USAGE.md)

## Compatability Tests 
#### CNFs should work with any Certified Kubernetes product and any CNI-compatible network that meet their functionality requirements.  The CNF Conformance Suite validates this by:
*  Performing CNI Plugin testing which:
    * Tests if CNI Plugin follows the [CNI specification](https://github.com/containernetworking/cni/blob/master/SPEC.md)
*  Performing K8s API usage testing by running [API snoop](https://github.com/cncf/apisnoop) on the cluster which:
    * Checks alpha endpoint usage
    * Checks beta endpoint usage
    * Checks generally available (GA) endpoint usage

## Statelessness Tests 
#### The CNF conformance suite checks if state is stored in a [custom resource definition](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/) or a separate database (e.g. [etcd](https://github.com/etcd-io/etcd)) rather than requiring local storage.  It also checks to see if state is resilient to node failure by:
*  Resetting the container and checking to see if the CNF comes back up
*  Using upstream projects for chaos engineering (e.g [Litmus](//https://github.com/litmuschaos/litmus))

## Security Tests 
#### CNF containers should be isolated from one another and the host.  The CNF Conformance suite uses tools like [OPA Gatekeeper](https://github.com/open-policy-agent/gatekeeper), [Falco](https://github.com/falcosecurity/falco), [Sysdig Inspect](https://github.com/draios/sysdig-inspect) and [gVisor](https://github.com/google/gvisor) to:
*  Check if any containers are running in privileged mode
*  Check if there are any shells
*  Check if any protected directories or files are accessed

## Scalability Tests  
#### The CNF conformance suite checks to see if CNFs support horizontal scaling (across multiple machines) and vertical scaling (between sizes of machines) by using the native K8s [kubectl](https://kubernetes.io/docs/reference/kubectl/cheatsheet/#scaling-resources) command to:
*  Test increasing/decreasing capacity
*  Test small scale autoscaling with kubectl
*  Test large scale autoscaling with load test tools like [CNF Testbed](https://github.com/cncf/cnf-testbed)
*  Test if the CNF control layer responds to retries for failed communication (e.g. using [Pumba](https://github.com/alexei-led/pumba) or [Blockade](https://github.com/worstcase/blockade) for network chaos and [Envoy](https://github.com/envoyproxy/envoy) for retries)

(see [scalability test usage documentation](https://github.com/cncf/cnf-conformance/blob/master/USAGE.md#scaling-tests))

## Configuration and Lifecycle Tests 
#### Configuration and lifecycle should be managed in a declarative manner, using [ConfigMaps](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/), [Operators](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/), or other [declarative interfaces](https://kubernetes.io/docs/concepts/overview/working-with-objects/kubernetes-objects/#understanding-kubernetes-objects).  The Conformance suite checks this by:

*  Testing if the CNF is installed using a [versioned](https://helm.sh/docs/topics/chart_best_practices/dependencies/#versions) Helm v3 chart
*  Searching for hardcoded IP addresses or subnets in the configuration
*  Checking for a liveness entry in the helm chart and if the container is responsive to it after a reset (e.g. by checking the [helm chart entry](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/))
*  Checking for a readiness entry in the helm chart and if the container is responsive to it after a reset
*  Checking if the pod/container can be started without mounting a volume (e.g. using [helm configuration](https://kubernetes.io/docs/tasks/configure-pod-container/configure-volume-storage/)) that has configuration files
*  Testing to see if we can start pods/containers and see that the application continues to perform (e.g. using [Litmus](https://github.com/litmuschaos/litmus))
*  Testing by reseting any child processes, and when the parent process is started, checking to see if those child processes are reaped (ie. monitoring processes with [Falco](https://github.com/falcosecurity/falco) or [sysdig-inspect](https://github.com/draios/sysdig-inspect))
*  Testing if the CNF can perform a rolling update (i.e. [kubectl rolling update](https://kubernetes.io/docs/tasks/run-application/rolling-update-replication-controller/))

## Observability Tests 
#### In order to maintain, debug, and have insight into a protected environment, its infrastructure elements must have the property of being observable. This means these elements must externalize their internal states in some way that lends itself to metrics, tracing, and logging. The Conformance suite checks this by:
*  Testing to see if there is traffic to [Fluentd](https://github.com/fluent/fluentd)
*  Testing to see if there is traffic to [Jaeger](https://github.com/jaegertracing/jaeger)
*  Testing to see if Prometheus rules for the CNF are configured correctly (e.g. using [Promtool](https://prometheus.io/docs/prometheus/latest/configuration/unit_testing_rules/))
*  Testing to see if there is traffic to [Prometheus](https://github.com/prometheus/prometheus)
*  Testing to see if the tracing calls are compatible with [OpenTelemetry](https://opentracing.io/) 
*  Testing to see if the monitoring calls are compatible with [OpenMetric](https://github.com/OpenObservability/OpenMetrics) 

## Installable and Upgradeable Tests
#### The CNF Conformance suite will check for usage of standard, in-band deployment tools such as Helm (version 3) charts. The Conformance suite checks this by:
*  Testing if the install script uses [Helm v3](https://github.com/helm/)
*  Testing if the CNF is published to a public helm chart repository.
*  Testing if the Helm chart is valid (e.g. using the [helm linter](https://github.com/helm/chart-testing))
*  Testing if the CNF can perform a rolling update (i.e. [kubectl rolling update](https://kubernetes.io/docs/tasks/run-application/rolling-update-replication-controller/))

## Hardware Resources and Scheduling Tests 
#### The CNF container should access all hardware and schedule to specific worker nodes by using a device plugin.  The CNF Conformance suite checks this by:

*  Checking if the CNF is accessing hardware in its configuration files
*  Testing if the CNF accessess hardware directly during run-time (e.g. accessing the host /dev or /proc from a mount)
*  Testing if the CNF accessess hugepages directly instead of via [Kubernetes resources](https://github.com/cncf/cnf-testbed/blob/c4458634deca5e8ab73adf118eedde32904c8458/examples/use_case/external-packet-filtering-on-k8s-nsm-on-packet/gateway.yaml#L29)
*  Testing if the CNF Testbed performance output shows adequate throughput and sessions using the [CNF Testbed](https://github.com/cncf/cnf-testbed) (vendor neutral) hardware environment.
