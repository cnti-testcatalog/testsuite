# Testsuite Categories

The CNF Test Suite program validates interoperability of CNF **workloads** supplied by multiple different vendors orchestrated by Kubernetes **platforms** that are supplied by multiple different vendors. The goal is to provide an open source test suite to enable both open and closed source CNFs to demonstrate conformance and implementation of best practices. For more detailed CLI documentation see the [usage document.](USAGE.md)

## Compatibility, Installability & Upgradability Tests

#### CNFs should work with any Certified Kubernetes product and any CNI-compatible network that meet their functionality requirements. The CNF Test suite will check for usage of standard, in-band deployment tools such as Helm (version 3) charts. The CNF test suite checks to see if CNFs support horizontal scaling (across multiple machines) and vertical scaling (between sizes of machines) by using the native K8s [kubectl](https://kubernetes.io/docs/reference/kubectl/cheatsheet/#scaling-resources). The CNF Test Suite validates this:

#### On workloads:

- Performing K8s API usage testing by running [API snoop](https://github.com/cncf/apisnoop) on the cluster which:
  - Checks alpha endpoint usage
  - Checks beta endpoint usage
  - Checks generally available (GA) endpoint usage
- Test increasing/decreasing capacity
- Test small scale autoscaling with kubectl
- Test large scale autoscaling with load test tools like [CNF Testbed](https://github.com/cncf/cnf-testbed)
- Test if the CNF control layer responds to retries for failed communication (e.g. using [Pumba](https://github.com/alexei-led/pumba) or [Blockade](https://github.com/worstcase/blockade) for network chaos and [Envoy](https://github.com/envoyproxy/envoy) for retries)
- Testing if the install script uses [Helm v3](https://github.com/helm/)
- Testing if the CNF is published to a public helm chart repository.
- Testing if the Helm chart is valid (e.g. using the [helm linter](https://github.com/helm/chart-testing))
- Testing if the CNF can perform a rolling update (i.e. [kubectl rolling update](https://kubernetes.io/docs/tasks/run-application/rolling-update-replication-controller/))
- Performing CNI Plugin testing which:
  - Tests if CNI Plugin follows the [CNI specification](https://github.com/containernetworking/cni/blob/master/SPEC.md)

## Microservice Tests

#### The CNF should be developed and delivered as a microservice. The CNF Test suite tests to determine the organizational structure and rate of change of the CNF being tested. Once these are known we can detemine whether or not the CNF is a microservice. See: [Microservice-Principles](https://networking.cloud-native-principles.org/cloud-native-microservice-principles):

#### On workloads:

- Check if the CNF have a reasonable startup time.
- Check the image size of the CNF.
- Checks for single process on pods.

## State Tests

#### The CNF test suite checks if state is stored in a [custom resource definition](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/) or a separate database (e.g. [etcd](https://github.com/etcd-io/etcd)) rather than requiring local storage. It also checks to see if state is resilient to node failure:

#### On workloads:

- Checking volume hostpath is found or not.
- Checks if no local volume is configured.
- Check if the CNF is usin elastic persistent volumes
- Checks for k8s database persistence.

## Reliability, Resilience & Availability Tests

[Cloud Native Definition](https://github.com/cncf/toc/blob/master/DEFINITION.md) requires systems to be Resilient to failures inevitable in cloud environments. CNF Resilience should be tested to ensure CNFs are designed to deal with non-carrier-grade shared cloud HW/SW platform:

#### On workloads:

- Checks for network latency
- Performs a disk fill
- Deletes a pod to test reliability and availability.
- Performs a memory hog test for resilience.
- Performs an IO stress test.
- Tests network corruption.
- Tests network duplication.
- Drains a node on the cluster.
- Checking for a liveness entry in the helm chart and if the container is responsive to it after a reset (e.g. by checking the [helm chart entry](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/))
- Checking for a readiness entry in the helm chart and if the container is responsive to it after a reset

## Observability & Diagnostic Tests

#### In order to maintain, debug, and have insight into a protected environment, infrastructure elements must have the property of being observable. This means these elements must externalize their internal states in some way that lends itself to metrics, tracing, and logging. The Test suite checks this:

#### On workloads:

- Testing to see if there is traffic to [Fluentd](https://github.com/fluent/fluentd)
- Testing to see if there is traffic to [Jaeger](https://github.com/jaegertracing/jaeger)
- Testing to see if Prometheus rules for the CNF are configured correctly (e.g. using [Promtool](https://prometheus.io/docs/prometheus/latest/configuration/unit_testing_rules/))
- Testing to see if there is traffic to [Prometheus](https://github.com/prometheus/prometheus)
- Testing to see if the monitoring calls are compatible with [OpenMetric](https://github.com/OpenObservability/OpenMetrics)
- Tests log output.

## Security Tests

#### CNF containers should be isolated from one another and the host. The CNF Test suite uses tools like [OPA Gatekeeper](https://github.com/open-policy-agent/gatekeeper), [Falco](https://github.com/falcosecurity/falco), and [Armosec Kubescape](https://github.com/armosec/kubescape):

#### On workloads:

- Check if any containers are running in privileged mode.
- Checks root user.
- Checks for privilege escalation.
- Checks symlink file system.
- Checks application credentials.
- Checks if the container or pods can access the host network.
- Checks for service accounts and mappings.
- Checks for ingress and egress being blocked.
- Privileged container checks.
- Verifies if there are insecure and dangerous capabilities.
- Checks network policies.
- Checks for non root containers.
- Checks PID and IPC privileges.
- Checks for Linux Hardening, eg. Selinux is used.
- Checks resource policies defined.
- Checks for immutable file systems.
- Verifies and checks if any hostpath mounts are used.

#### On platforms:

- Check if there are any shells

## Configuration Tests

#### Configuration should be managed in a declarative manner, using [ConfigMaps](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/), [Operators](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/), or other [declarative interfaces](https://kubernetes.io/docs/concepts/overview/working-with-objects/kubernetes-objects/#understanding-kubernetes-objects). The Test suite checks this by:

#### On workloads:

- Testing if the CNF is installed using a [versioned](https://helm.sh/docs/topics/chart_best_practices/dependencies/#versions) Helm v3 chart
- Searching for hardcoded IP addresses, subnets, or node ports in the configuration
- Checking if the pod/container can be started without mounting a volume (e.g. using [helm configuration](https://kubernetes.io/docs/tasks/configure-pod-container/configure-volume-storage/)) that has configuration files
- Testing by reseting any child processes, and when the parent process is started, checking to see if those child processes are reaped (ie. monitoring processes with [Falco](https://github.com/falcosecurity/falco) or [sysdig-inspect](https://github.com/draios/sysdig-inspect))
- Testing if there are any (non-declarative) hardcoded IP addresses or subnet masks
- Tests if nodeport is not used.
- Tests hostport is not used.
- Checks for secrets used or configured.
- Tests immutable configmaps.


Tools to study/use for such testing methodology: The previously mentioned Pumba and Blocade, [ChaosMesh](https://github.com/pingcap/chaos-mesh), [Mitmproxy](https://github.com/mitmproxy/mitmproxy/), Istio for "[Network Resilience](https://istio.io/docs/concepts/traffic-management/#network-resilience-and-testing)", kill -STOP -CONT, [LimitCPU](http://limitcpu.sourceforge.net/), [Packet pROcessing eXecution (PROX) engine](https://wiki.opnfv.org/pages/viewpage.action?pageId=12387840) as [Impair Gateway](https://github.com/opnfv/samplevnf/blob/master/VNFs/DPPD-PROX/helper-scripts/rapid/impair.cfg).
