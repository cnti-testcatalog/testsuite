# CNF Test Suite List of Tests - v0.27.0


## Summary
This document provides a summary of the tests included in the CNF Test Suite. Each test lists a general overview of what the test does, a link to the test code for that test, and links to additional information when relevant/available.

To learn how to run these tests, see the [USAGE.md](../USAGE.md)

To learn why these tests were written, see the [RATIONALE.md](../RATIONALE.md)


List of Workload Tests
---

# Compatibility, Installability, and Upgradability Category


<!-- TODO: look into using the combined alias and a single score

## [Increase decrease capacity](https://github.com/cncf/cnf-testsuite/blob/main/src/tasks/workload/compatibility.cr#L168)
- :memo: Candidate for CNF Certification
- :heavy_check_mark: Added to CNF Test Suite in release vXXX
- Expectation: pod should be capable of scaling up and down as needed



<b>increase_decrease_capacity test:</b> HPA (horizonal pod autoscale) will autoscale replicas to accommodate when there is an increase of CPU, memory or other configured metrics to prevent disruption by allowing more requests 
by balancing out the utilisation across all of the pods.

Decreasing replicas works the same as increase but rather scale down the number of replicas when the traffic decreases to the number of pods that can handle the requests.

You can read more about horizonal pod autoscaling to create replicas [here](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/) and in the [K8s scaling cheatsheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/#scaling-resources).
</p>

-->

## [Increase decrease capacity:](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/compatibility.cr#L168)

<b>The increase and decrease capacity tests:</b> HPA (horizonal pod autoscale) will autoscale replicas to accommodate when there is an increase of CPU, memory or other configured metrics to prevent disruption by allowing more requests 
by balancing out the utilisation across all of the pods.

Decreasing replicas works the same as increase but rather scale down the number of replicas when the traffic decreases to the number of pods that can handle the requests.

You can read more about horizonal pod autoscaling to create replicas [here](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/) and in the [K8s scaling cheatsheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/#scaling-resources).
</p>

  
### [Increase capacity](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/compatibility.cr#L184) 
- Expectation: The number of replicas for a Pod increases <!-- see #Increase-decrease-capacity -->

**What's tested:** The pod is increased and replicated to 3 for the CNF image or release being tested.

### [Decrease capacity](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/compatibility.cr#L213)
- Expectation: The number of replicas for a Pod decreases <!-- see #Increase-decrease-capacity -->

**What's tested:** After `increase_capacity` increases the replicas to 3, it decreases back to 1.

## [Helm chart published](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/compatibility.cr#L406)
- Expectation: tbd

**What's tested:** Checks if a Helm chart is published

## [Helm chart valid](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/compatibility.cr#L449)
- Test if the [Helm chart is valid](https://github.com/helm/chart-testing)
- Expectation: tbd

**What's tested:** This runs `helm lint` against the helm chart being tested. You can read more about the helm lint command at [helm.sh](https://helm.sh/docs/helm/helm_lint/)

## [Helm deploy](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/compatibility.cr#L339)
- Expectation: tbd

**What's tested:** TBD

## [Install script Helm v3](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/compatibility.cr#L372)
- Expectation: Test if the install script uses [Helm v3](https://github.com/helm/)

**What's tested:** This checks if helm v3 or greater is used by the helm charts.

## [Rolling update](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/compatibility.cr#L8)
- Expectation: test if the CNF can perform a [rolling update](https://kubernetes.io/docs/tutorials/kubernetes-basics/update/update-intro/)

**What's tested:** TBD

## [Rolling version change](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/compatibility.cr#L8)
- Expectation: tbd

**What's tested:** TBD

## [Rolling downgrade](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/compatibility.cr#L8)
- Expectation: tbd

**What's tested:** TBD

## [Rollback](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/compatibility.cr#L87)
- Expectation: tbd

**What's tested:** TBD

## [CNI compatible](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/compatibility.cr#L588)
- Expectation: CNF should be compatible with multiple and different CNIs

**What's tested:** This installs temporary kind clusters and will test the CNF against both Calico and Cilium CNIs. 


## [Kubernetes Alpha APIs - Proof of Concept](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/configuration.cr#L499)
- Expectation: CNF should not use Kubernetes alpha APIs

**What's tested:** This checks if a CNF uses Kubernetes alpha or unstable APIs


# Microservice Category

## [Reasonable image size](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/microservice.cr#L268) 
- Expectation: CNF image size is under 5 gigs

**What's tested:** Checks the size of the image used.

## [Reasonable startup time](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/microservice.cr#L183)
- Expectation: CNF starts up under one minute 

**What's tested:** TBD

## [Single process type in one container](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/microservice.cr#L359)
- Expectation: CNF container has one process type

**What's tested:** This verifies that there is only one process type within one container. This does not count against child processes. Example would be nginx or httpd could have a parent process and then 10 child processes but if both nginx and httpd were running, this test would fail.

## [Service discovery](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/microservice.cr#L413)
- Expectation: CNFs should not expose their containers as a service

**What's tested:** This tests and checks if a container for the CNF has services exposed. Application access for microservices within a cluster should be exposed via a Service. Read more about K8s Service [here](https://kubernetes.io/docs/concepts/services-networking/service/).

  
## [Shared database](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/microservice.cr#L19)  
- Expectation: Multiple microservices should not share the same database.

**What's tested:** This tests if multiple CNFs are using the same database.

# State Category

## [Node drain](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/state.cr#L209) 
- Expectation: A node will be drained and rescheduled onto other available node(s).

**What's tested:** A node is drained and rescheduled to another node, passing with a liveness and readiness check. This will skip when the cluster only has a single node.

## [Volume hostpath not found](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/state.cr#L419) 
- Expectation: Volume host path configurations should not be used.

**What's tested:** This tests if volume host paths are configured and used by the CNF.

## [No local volume configuration](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/state.cr#L457) 
- Expectation: Local storage should not be used or configured.

**What's tested:** This tests if local volumes are being used for the CNF.

## [Elastic volumes](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/state.cr#L321) 
- Expectation: Elastic persistent volumes should be configured for statefulness.

**What's tested:** This checks for elastic persistent volumes in use by the CNF.

## [Database persistence](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/state.cr#L358)
- Expectation: Elastic volumes and or statefulsets should be used for databases to maintain a minimum resilience level in K8s clusters.

**What's tested:** This checks if elastic volumes and stateful sets are used for MySQL databases. If no MySQL database is found, the test is skipped.

# Reliability, Resilience and Availability Category

## [CNF under network latency](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/reliability.cr#L231)
- Expectation: The CNF should continue to function when network latency occurs

**What's tested:** [This experiment](https://docs.litmuschaos.io/docs/pod-network-latency/) causes network degradation without the pod being marked unhealthy/unworthy of traffic by kube-proxy (unless you have a liveness probe of sorts that measures latency and restarts/crashes the container). The idea of this experiment is to simulate issues within your pod network OR microservice communication across services in different availability zones/regions etc.

The applications may stall or get corrupted while they wait endlessly for a packet. The experiment limits the impact (blast radius) to only the traffic you want to test by specifying IP addresses or application information. This experiment will help to improve the resilience of your services over time.


## [CNF with host disk fill](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/reliability.cr#L390)
- Expectation: The CNF should continue to function when disk fill occurs

**What's tested:** [Stressing the disk](https://litmuschaos.github.io/litmus/experiments/categories/pods/disk-fill/) with continuous and heavy IO for example can cause degradation in reads written by other microservices that use this shared disk for example modern storage solutions for Kubernetes to use the concept of storage pools out of which virtual volumes/devices are carved out. Another issue is the amount of scratch space eaten up on a node which leads to the lack of space for newer containers to get scheduled (Kubernetes too gives up by applying an "eviction" taint like "disk-pressure") and causes a wholesale movement of all pods to other nodes. Similarly with CPU chaos, by injecting a rogue process into a target container, we starve the main microservice process (typically PID 1) of the resources allocated to it (where limits are defined) causing slowness in application traffic or in other cases unrestrained use can cause the node to exhaust resources leading to the eviction of all pods. So this category of chaos experiment helps to build the immunity on the application undergoing any such stress scenario.


##  [Pod delete](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/reliability.cr#L441)
- Expectation: The CNF should continue to function when pod delete occurs

**What's tested:** [This experiment](https://litmuschaos.github.io/litmus/experiments/categories/pods/pod-delete/) helps to simulate such a scenario with forced/graceful pod failure on specific or random replicas of an application resource and checks the deployment sanity (replica availability & uninterrupted service) and recovery workflow of the application.

## [Memory hog](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/reliability.cr#L495)
- Expectation: The CNF should continue to function when pod memory hog occurs

**What's tested:** The [pod-memory hog](https://litmuschaos.github.io/litmus/experiments/categories/pods/pod-memory-hog/) experiment launches a stress process within the target container - which can cause either the primary process in the container to be resource constrained in cases where the limits are enforced OR eat up available system memory on the node in cases where the limits are not specified.  


## [IO Stress](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/reliability.cr#L549)
- Expectation: The CNF should continue to function when pod io stress occurs

**What's tested:** This test stresses the disk with with continuous and heavy IO to cause degradation in reads/ writes by other microservices that use this shared disk. 

## [Network corruption](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/reliability.cr#L284)
- Expectation: The CNF should continue to function when pod network corruption occurs

**What's tested: TBD**

## [Network duplication](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/reliability.cr#L337)
- Expectation: The CNF should continue to function when pod network duplication occurs

**What's tested: TBD**

## [Helm chart liveness entry](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/reliability.cr#L15)
-  Expectation: The Helm chart should have a liveness probe

**What's tested: TBD**

## [Helm chart readiness entry](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/reliability.cr#L45)
- Expectation: The Helm chart should have a readiness probe

**What's tested: TBD**

# Observability and Diagnostic Category

## [Use stdout/stderr for logs](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/observability.cr#L13)
- Expectation: Resource output logs should be sent to STDOUT/STDERR

**What's tested: TBD** This checks and verifies that STDOUT/STDERR is configured for logging.

For example, running `kubectl get logs` returns useful information for diagnosing or troubleshooting issues. 

## [Prometheus installed](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/observability.cr#L42)
- Expectation: Prometheus is being used for the cluster and CNF for metrics.

**What's tested: TBD** Tests for the presence of [Prometheus](https://prometheus.io/) or if the CNF emit prometheus traffic.

## [Fluentd logs](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/observability.cr#L170)
- Expectation: Fluentd is capturing logs.

**What's tested:** Checks for fluentd presence and if logs are being captured for fluentd.


## [OpenMetrics compatible](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/observability.cr#L146)
- Expectation: CNF should emit OpenMetrics compatible traffic.

**What's tested:** Checks if OpenMetrics is being used and or compatible.

## [Jaeger tracing](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/observability.cr#L203)
- Expectation: The CNF uses tracing.

**What's tested:** Checks if Jaeger is configured and tracing is being used.


# Security Category

## [Container socket mounts](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/security.cr#L51)
- :heavy_check_mark: Added to CNF Test Suite in release v0.27.0
- Expectation: Container engine daemon sockets should not be mounted as volumes

**What's tested**
<b>Container Socket Mounts Details:</b> Container daemon socket bind mounts allows access to the container engine on the node. This access can be used for privilege escalation and to manage containers outside of Kubernetes, and hence should not be allowed.



## [Privileged Mode](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/security.cr#L125)
- Expectation: Containers should not run in privileged mode

**What's tested:** Checks if any containers are running in privileged mode (using [OPA Gatekeeper](https://github.com/open-policy-agent/gatekeeper) Policy Controller for Kubernetes)


## [External IPs](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/security.cr#L31)
- :heavy_check_mark: Added to CNF Test Suite in release v0.27.0
- Expectation: A CNF should not run services with external IPs

**What's tested:** Checks if the CNF has services with external IPs configured


## [Root user](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/security.cr#L71)
- Expectation: Containers should not run as a [root user](https://github.com/cncf/cnf-wg/blob/best-practice-no-root-in-containers/cbpps/0002-no-root-in-containers.md)

**What's tested:** Checks if any containers are running as root user

## [Privilege escalation](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/security.cr#L156)
- Expectation: Containers should not allow for [privilege escalation](https://bit.ly/C0016_privilege_escalation)

**What's tested: TBD** <b>Privilege Escalation:</b> Check that the allowPrivilegeEscalation field in securityContext of container is set to false.

See more at [ARMO-C0016](https://bit.ly/C0016_privilege_escalation)


## [Symlink file system](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/security.cr#L175)
- Expectation: No containers allow a [symlink](https://bit.ly/C0058_symlink_filesystem) attack

**What's tested:**
This control checks the vulnerable versions and the actual usage of the subPath feature in all Pods in the cluster.

See more at [ARMO-C0058](https://bit.ly/C0058_symlink_filesystem)

## [Application credentials](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/security.cr#L194)
- Exepectation: Application credentials should not be found in configuration files

**What's tested:**
Check if the pod has sensitive information in environment variables, by using list of known sensitive key names. Check if there are configmaps with sensitive information.

See more at [ARMO-C0012](https://bit.ly/C0012_application_credentials)


## [Host network](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/security.cr#L213)
- Expectation: PODs should not have access to the host systems network.

**What's tested:** Checks if there is a [host network attached to a pod](https://bit.ly/C0041_hostNetwork). See more at [ARMO-C0041](https://bit.ly/C0041_hostNetwork)



## [Service account mapping](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/security.cr#L232)
- Expectation: The [automatic mapping](https://bit.ly/C0034_service_account_mapping) of service account tokens should be disabled. 

**What's tested:** Check if service accounts are automatically mapped. See more at [ARMO-C0034](https://bit.ly/C0034_service_account_mapping).


## [Ingress and Egress blocked](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/security.cr#L335)
- Expectation: [Ingress and Egress traffic should be blocked on Pods](https://bit.ly/3bhT10s).

**What's tested:** Checks Ingress and Egress traffic policy


## [Privilege escalation, Kubescape](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/security.cr#L156) 
- Expectation: Containers should not allow privilege escalation

**What's tested:** Checks if any containers are running in privileged mode. Read more at [ARMO-C0057](https://bit.ly/31iGng3)



## [Insecure capabilities](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/security.cr#L272)
- Expectation: Containers should not have insecure capabilities enabled

**What's tested:** Checks for insecure capabilities. See more at [ARMO-C0046](https://bit.ly/C0046_Insecure_Capabilities)

This test checks against a [blacklist of insecure capabilities](https://github.com/FairwindsOps/polaris/blob/master/checks/insecureCapabilities.yaml).
    

## [Dangerous capabilities](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/security.cr#L293)
- Expectation: Containers should not have dangerous capabilities enabled

**What's tested:**
This test checks against a [denylist of dangerous capabilities](https://github.com/FairwindsOps/polaris/blob/master/checks/dangerousCapabilities.yaml).

See more at [ARMO-C0028](https://bit.ly/C0028_Dangerous_Capabilities)


## [Network policies](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/security.cr#L398)
- Expectation: Namespaces should have network policies defined

**What's tested:** Checks if network policies are defined for namespaces. Read more at [ARMO-C0011](https://bit.ly/2ZEwb0A).

### NOTE: only in usage
<b>Remediation:</b> Define network policies or use similar network protection mechanisms.
    
## [Non-root containers](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/security.cr#L377)
- Expectation: Containers should run with non-root user with non-root group membership

**What's tested:** Checks if containers are running with non-root user with non-root membership. Read more at [ARMO-C0013](https://bit.ly/2Zzlts3)


## [Host PID/IPC privileges](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/security.cr#L356)
- Expectation: Containers should not have hostPID and hostIPC privileges

**What's tested:** Checks if containers are running with hostPID or hostIPC privileges. Read more at [ARMO-C0038](https://bit.ly/3nGvpIQ)


## [Linux hardening](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/security.cr#L251)
- Expectation: Security services are being used to harden application

**What's tested:** Checks if security services are being used to harden the application. Read more at [ARMO-C0055](https://bit.ly/2ZKOjpJ)

## [Resource policies](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/security.cr#L314)
- Expectation: Containers should have resource limits defined

**What's tested:**
Check for each container if there is a ‘limits’ field defined. Check for each limitrange/resourcequota if there is a max/hard field defined, respectively. Read more at [ARMO-C0009](https://bit.ly/3Ezxkps).



## [Immutable File Systems](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/security.cr#L441)
- Expectation: Containers should have immutable file system

**What's tested:**
Checks whether the readOnlyRootFilesystem field in the SecurityContext is set to true. Read more at [ARMO-C0017](https://bit.ly/3pSMtxK)



## [HostPath Mounts](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/security.cr#L462) 
- Expectation: Containers should not have hostPath mounts 

**What's tested:** TBD
Read more at [ARMO-C0045](https://bit.ly/3EvltIL)

# Configuration Category

## [Default namespaces](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/security.cr#L) 
- Expectation: To check if resources of the CNF are not in the default namespace

**What's tested:** TBD

## [Latest tag](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/configuration.cr#L) 
- Expectation: Checks if a CNF is using 'latest' tag instead of a version.

**What's tested:** TBD

## [Require labels](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/configuration.cr#L18) 
- :heavy_check_mark: Added to CNF Test Suite in release v0.27.0
- Expectation: Checks if pods are using the 'app.kubernetes.io/name' label

**What's tested:** TBD

## [Versioned tag](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/configuration.cr#L80) 
- Expectation: Checks for versioned tags on all images using OPA Gatekeeper

**What's tested:** TBD

## [IP addresses](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/configuration.cr#L39) 
- Expectation: Checks for hardcoded IP addresses or subnet masks.

**What's tested:** TBD

## [nodePort not used](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/configuration.cr#L131) 
- Expectation: Checks for configured node ports in the service configuration.

**What's tested:** TBD

## [hostPort not used](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/configuration.cr#L166) 
- Expectation: Checks for configured host ports in the service configuration.

**What's tested:** TBD

## [Hardcoded IP addresses in K8s runtime configuration](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/configuration.cr#L213) 
- Expectation: Checks for hardcoded IP addresses or subnet masks in the K8s runtime configuration.

**What's tested:** TBD

## [Secrets used](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/configuration.cr#L257) 
- Expectation: Checks for K8s secrets.

**What's tested:** TBD

## [Immutable configmap](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/configuration.cr#L362) 
- Expectation: Checks for K8s version and if immutable configmaps are enabled.

**What's tested:** TBD

## [Pod DNS errors](https://github.com/cncf/cnf-testsuite/blob/v0.26.0/src/tasks/workload/reliability.cr#L604)
- :heavy_check_mark: Added to CNF Test Suite in release v0.26.0
- Expectation: Test if the CNF crashes when pod dns error occurs

**What's tested:** TBD



---

List of Platform Tests
---


## [K8s Conformance](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/platform/platform.cr#L21)
- Expectation: The K8s cluster passes the K8s conformance tests

**What's tested:** 
The K8s conformance test runs against the cluster.  See  https://github.com/cncf/k8s-conformance for details on what is tested.

## [ClusterAPI enabled](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/platform/platform.cr#L88)
- Expectation: The cluster has Cluster API enabled which manages at least one Node.

**What's tested:** TBD

## [OCI Compliant](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/platform/hardware_and_scheduling.cr#L15)
- Expectation: The platform passes OCI compliance

**What's tested:** TBD

## (PoC) [Worker reboot recovery](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/platform/resilience.cr#L15)
- Expectation: Pods should reschedule after a node failure.
- **WARNING**: this is a destructive test and will reboot your _host_ node! Do not run this unless you have completely separate cluster, e.g. development or test cluster.

**What's tested:**
Run node failure test which forces a reboot of the Node ("host system"). The Pods on that node should be rescheduled to a new Node.


## [Cluster admin](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/platform/security.cr#L33)
- Expectation: The [cluster admin role should not be bound to a Pod](https://bit.ly/C0035_cluster_admin)

**What's tested:**
Check which subjects have cluster-admin RBAC permissions – either by being bound to the cluster-admin clusterrole, or by having equivalent high privileges.

   

## [Control plane hardening](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/platform/security.cr#L13)
- Expectation: Verify that the [the k8s control plane is hardened](https://bit.ly/C0005_Control_Plane)

**What's tested: TBD**
See https://bit.ly/C0005_Control_Plane


## [Dashboard exposed](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/platform/security.cr#L54)
- Expectation: The K8s dashboard should not exposed to the public internet

**What's tested: TBD**
See more details in Kubescape documentation: [C-0047 - Exposed dashboard](https://hub.armo.cloud/docs/c-0047)

## [Tiller images](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/platform/security.cr#L75) 
- Added in release v0.27.0
- Expectation: Containers should not use tiller images

**What's tested:** Checks if containers are using any tiller images
