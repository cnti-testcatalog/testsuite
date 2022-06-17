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

[**Rational & Reasoning**](../RATIONALE.md#to-test-the-increasing-and-decreasing-of-capacity-increase_decrease_capacity)


## [Helm chart published](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/compatibility.cr#L406)
- Expectation: The Helm chart is published in a Helm Repsitory.

**What's tested:** Checks if the helm chart is found in a remote repository when running [`helm search`](https://helm.sh/docs/helm/helm_search_repo/).


[**Rational & Reasoning**](../RATIONALE.md#test-if-the-helm-chart-is-valid-helm_chart_valid)


## [Helm chart valid](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/compatibility.cr#L449)
- Expectation: No syntax or validation problems are found in the chart.

**What's tested:** Checks the syntax & validity of the chart using [`helm lint`](https://helm.sh/docs/helm/helm_lint/)

[**Rational & Reasoning**](../RATIONALE.md#test-if-the-helm-chart-is-valid-helm_chart_valid)



## [Helm deploy](../USAGE.md#helm-deploy)
- Expectation: The CNF was installed using Helm.

**What's tested:** Checks if the CNF is installed by using a Helm Chart.

[**Rational & Reasoning**](../RATIONALE.md#test-if-the-helm-deploys-helm_deploy)

## [Rollback:](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/compatibility.cr#L87)
- Expectation: The CNF Software version can be successfully incremented, then rolled back.

**What's tested:** Checks if the Pod can be upgraded to a new software version, then restored back to the orginal software version by using the [Kubectl Set Image](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#-em-image-em-) & [Kubectl Rollout Undo](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#rollout) commands.

[**Rational & Reasoning**](../RATIONALE.md#to-check-if-a-cnf-version-can-be-rolled-back-rollback)


### [Rolling update](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/compatibility.cr#L8)
- Expectation: The CNF Software version can be successfully incremented.

**What's tested:** Checks if the Pod can be upgraded to a new software version by using the [Kubectl Set Image](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#-em-image-em-)

[**Rational & Reasoning**](../RATIONALE.md#to-test-if-the-cnf-can-perform-a-rolling-update-rolling_update)


### [Rolling version change](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/compatibility.cr#L8)
- Expectation: The CNF Software version is successfully rolled back to its original version.

**What's tested:** Checks if the Pod can be rolled back to the original software version by using the [Kubectl Set Image](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#-em-image-em-) to perform a rollback.

[**Rational & Reasoning**](../RATIONALE.md#to-check-if-a-cnf-version-can-be-downgraded-through-a-rolling_version_change-rolling_version_change)


### [Rolling downgrade](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/compatibility.cr#L8)
- Expectation: The CNF Software version is successfully downgraded to a software version older than the orginal installation version.

**What's tested:** Checks if the Pod can be rolled back older software version(Older than the original software version) by using the [Kubectl Set Image](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#-em-image-em-) to perform a downgrade.

[**Rational & Reasoning**](../RATIONALE.md#to-check-if-a-cnf-version-can-be-downgraded-through-a-rolling_downgrade-rolling_downgrade)




## [CNI compatible](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/compatibility.cr#L588)
- Expectation: CNF should be compatible with multiple and different CNIs

**What's tested:** This installs temporary kind clusters and will test the CNF against both Calico and Cilium CNIs. 

[**Rational & Reasoning**](../RATIONALE.md#to-check-if-the-cnf-is-compatible-with-different-cnis-cni_compatibility)



## [Kubernetes Alpha APIs - Proof of Concept](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/configuration.cr#L499)
- Expectation: CNF should not use Kubernetes alpha APIs

**What's tested:** This checks if a CNF uses alpha or unstable versions of Kubernetes APIs

[**Rational & Reasoning**](../RATIONALE.md#poc-to-check-if-a-cnf-uses-kubernetes-alpha-apis-alpha_k8s_apis-alpha_k8s_apis)


# Microservice Category

## [Reasonable image size](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/microservice.cr#L268) 
- Expectation: CNF image size is under 5 gigs

**What's tested:** Checks the size of the image used.

[**Rational & Reasoning**](../RATIONALE.md#to-check-if-the-cnf-has-a-reasonable-image-size-reasonable_image_size)


## [Reasonable startup time](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/microservice.cr#L183)
- Expectation: CNF starts up under one minute 

**What's tested:** Checks how long the it takes for the CNF to pass a Readiness Probe and reach a ready/running state.

[**Rational & Reasoning**](../RATIONALE.md#to-check-if-the-cnf-have-a-reasonable-startup-time-reasonable_startup_time)


## [Single process type in one container](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/microservice.cr#L359)
- Expectation: CNF container has one process type

**What's tested:** This verifies that there is only one process type within one container. This does not count against child processes. Example would be nginx or httpd could have a parent process and then 10 child processes but if both nginx and httpd were running, this test would fail.

[**Rational & Reasoning**](../RATIONALE.md#to-check-if-the-cnf-has-multiple-process-types-within-one-container-single_process_type)


## [Service discovery](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/microservice.cr#L413)
- Expectation: CNFs accessible to other applications should be exposed via a Service.

**What's tested:** This tests and checks if the containers within a CNF have services exposed via a Kubernetes Service resource. Application access for microservices within a cluster should be exposed via a Service. Read more about K8s Service [here](https://kubernetes.io/docs/concepts/services-networking/service/).

[**Rational & Reasoning**](../RATIONALE.md#to-check-if-the-cnf-exposes-any-of-its-containers-as-a-service-service_discovery-service_discovery)

  
## [Shared database](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/microservice.cr#L19)  
- Expectation: Multiple microservices should not share the same database.

**What's tested:** This tests if multiple CNFs are using the same database.

[**Rational & Reasoning**](../RATIONALE.md#to-check-if-the-cnf-uses-a-shared-database-shared_database)


# State Category

## [Node drain](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/state.cr#L209) 
- Expectation: All workload resources are successfully rescheduled onto other available node(s).

**What's tested:** A node is drained and workload resources rescheduled to another node, passing with a liveness and readiness check. This will skip when the cluster only has a single node.

[**Rational & Reasoning**](../RATIONALE.md#test-if-the-cnf-crashes-when-node-drain-occurs-node_drain)


## [Volume hostpath not found](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/state.cr#L419) 
- Expectation: Volume host path configurations should not be used.

**What's tested:** This tests if volume host paths are configured and used by the CNF.

[**Rational & Reasoning**](../RATIONALE.md#to-test-if-the-cnf-uses-a-volume-host-path-volume_hostpath_not_found)


## [No local volume configuration](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/state.cr#L457) 
- Expectation: Local storage should not be used or configured.

**What's tested:** This tests if local volumes are being used for the CNF.

[**Rational & Reasoning**](../RATIONALE.md#to-test-if-the-cnf-uses-local-storage-no_local_volume_configuration)


## [Elastic volumes](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/state.cr#L321) 
- Expectation: Elastic persistent volumes should be configured for statefulness.

**What's tested:** This checks for elastic persistent volumes in use by the CNF.

[**Rational & Reasoning**](../RATIONALE.md#to-test-if-the-cnf-uses-elastic-volumes-elastic_volumes)


## [Database persistence](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/state.cr#L358)
- Expectation: Elastic volumes and or statefulsets should be used for databases to maintain a minimum resilience level in K8s clusters.

**What's tested:** This checks if elastic volumes and stateful sets are used for MySQL databases. If no MySQL database is found, the test is skipped.
[**Rational & Reasoning**](../RATIONALE.md#to-test-if-the-cnf-uses-a-database-with-either-statefulsets-elastic-volumes-or-both-database_persistence)


# Reliability, Resilience and Availability Category

## [CNF under network latency](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/reliability.cr#L231)
- Expectation: The CNF should continue to function when network latency occurs

**What's tested:** [This experiment](https://docs.litmuschaos.io/docs/pod-network-latency/) causes network degradation without the pod being marked unhealthy/unworthy of traffic by kube-proxy (unless you have a liveness probe of sorts that measures latency and restarts/crashes the container). The idea of this experiment is to simulate issues within your pod network OR microservice communication across services in different availability zones/regions etc.

The applications may stall or get corrupted while they wait endlessly for a packet. The experiment limits the impact (blast radius) to only the traffic you want to test by specifying IP addresses or application information. This experiment will help to improve the resilience of your services over time.

[**Rational & Reasoning**](../RATIONALE.md#test-if-the-cnf-crashes-when-network-latency-occurs-pod_network_latency)



## [CNF with host disk fill](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/reliability.cr#L390)
- Expectation: The CNF should continue to function when disk fill occurs and pods should not be evicted to another node.

**What's tested:** [This experiment](https://litmuschaos.github.io/litmus/experiments/categories/pods/disk-fill/) stresses the disk with continuous and heavy IO to cause degradation in the shared disk. This experiment also reduces the amount of scratch space available on a node which can lead to a lack of space for newer containers to get scheduled. This can cause (Kubernetes gives up by applying an "eviction" taint like "disk-pressure") a wholesale movement of all pods to other nodes. 

[**Rational & Reasoning**](../RATIONALE.md#test-if-the-cnf-crashes-when-disk-fill-occurs-disk_fill)


##  [Pod delete](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/reliability.cr#L441)
- Expectation: The CNF should continue to function when pod delete occurs

**What's tested:** [This experiment](https://litmuschaos.github.io/litmus/experiments/categories/pods/pod-delete/) helps to simulate such a scenario with forced/graceful pod failure on specific or random replicas of an application resource and checks the deployment sanity (replica availability & uninterrupted service) and recovery workflow of the application.

[**Rational & Reasoning**](../RATIONALE.md#test-if-the-cnf-crashes-when-pod-delete-occurs-pod_delete)


## [Memory hog](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/reliability.cr#L495)
- Expectation: The CNF should continue to function when pod memory hog occurs

**What's tested:** The [pod-memory hog](https://litmuschaos.github.io/litmus/experiments/categories/pods/pod-memory-hog/) experiment launches a stress process within the target container - which can cause either the primary process in the container to be resource constrained in cases where the limits are enforced OR eat up available system memory on the node in cases where the limits are not specified.  

[**Rational & Reasoning**](../RATIONALE.md#test-if-the-cnf-crashes-when-pod-memory-hog-occurs-pod_memory_hog)



## [IO Stress](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/reliability.cr#L549)
- Expectation: The CNF should continue to function when pod io stress occurs

**What's tested:** This test stresses the disk with continuous and heavy IO to cause degradation in reads/ writes by other microservices that use this shared disk.

[**Rational & Reasoning**](../RATIONALE.md#test-if-the-cnf-crashes-when-pod-io-stress-occurs-pod_io_stress)



## [Network corruption](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/reliability.cr#L284)
- Expectation: The CNF should be resilient to a lossy/flaky network and should continue to provide some level of availability.

**What's tested:** It injects packet corruption on the CNF by starting a traffic control (tc) process with netem rules to add egress packet corruption.

[**Rational & Reasoning**](../RATIONALE.md#test-if-the-cnf-crashes-when-pod-network-corruption-occurs-pod_network_corruption)


## [Network duplication](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/reliability.cr#L337)
- Expectation: The CNF should continue to function and be resilient to a duplicate network.

**What's tested:** This test injects network duplication into the CNF by starting a traffic control (tc) process with netem rules to add egress delays. 

[**Rational & Reasoning**](../RATIONALE.md#test-if-the-cnf-crashes-when-pod-network-duplication-occurs-pod_network_duplication)


## [Helm chart liveness entry](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/reliability.cr#L15)
-  Expectation: The Helm chart should have a liveness probe configured.

**What's tested:** This test scans all of the CNFs workload resources and check if a Liveness Probe has been configuered for each container.

[**Rational & Reasoning**](../RATIONALE.md#to-test-if-there-is-a-liveness-entry-in-the-helm-chart-liveness)


## [Helm chart readiness entry](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/reliability.cr#L45)
- Expectation: The Helm chart should have a readiness probe configured.

**What's tested:** This test scans all of the CNFs workload resources and check if a Readiness Probe has been configuered for each container.

[**Rational & Reasoning**](../RATIONALE.md#to-test-if-there-is-a-readiness-entry-in-the-helm-chart-readiness)


# Observability and Diagnostic Category

## [Use stdout/stderr for logs](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/observability.cr#L13)
- Expectation: Resource output logs should be sent to STDOUT/STDERR

**What's tested:** This checks and verifies that STDOUT/STDERR logging is configured for the CNF.

[**Rational & Reasoning**](../RATIONALE.md#to-check-if-logs-are-being-sent-to-stdoutstderr-standard-out-standard-error-instead-of-a-log-file-log_output)

## [Prometheus installed](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/observability.cr#L42)
- Expectation: The CNF is configured and sending metrics to a Prometheus server.

**What's tested:** Tests for the presence of [Prometheus](https://prometheus.io/) and if the CNF configured to sent metrics to the prometheus server.

[**Rational & Reasoning**](../RATIONALE.md#to-check-if-prometheus-is-installed-and-configured-for-the-cnf-prometheus_traffic)


## [Fluentd logs](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/observability.cr#L170)
- Expectation: Fluentd is install and capturing logs for the CNF.

**What's tested:** Checks for fluentd presence and if the CNFs logs are being captured by fluentd.

[**Rational & Reasoning**](../RATIONALE.md#to-check-if-logs-and-data-are-being-routed-through-fluentd-routed_logs)


## [OpenMetrics compatible](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/observability.cr#L146)
- Expectation: CNF should emit OpenMetrics compatible traffic.

**What's tested:** Checks if the CNFs metrics are [OpenMetrics](https://openmetrics.io/) compliant.

[**Rational & Reasoning**](../RATIONALE.md#to-check-if-openmetrics-is-being-used-and-or-compatible-open_metrics)

## [Jaeger tracing](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/observability.cr#L203)
- Expectation: The CNF is sending traces to Jaeger.

**What's tested:** Checks if Jaeger installed and the CNF is configured and sending traces to the Jaeger Server.

[**Rational & Reasoning**](../RATIONALE.md#to-check-if-tracing-is-being-used-with-jaeger-tracing)


# Security Category

## [Container socket mounts](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/security.cr#L51)
- :heavy_check_mark: Added to CNF Test Suite in release v0.27.0
- Expectation: Container runtime sockets should not be mounted as volumes

**What's tested** This test checks all of the CNFs containers and looks to see if any of them have access a container runtime socket from the host.
[**Rational & Reasoning**](../RATIONALE.md#to-check-if-the-cnf-performs-a-cri-socket-mount-container_sock_mounts)


## [Privileged Mode](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/security.cr#L420)
- Expectation: Containers should not run in privileged mode

**What's tested:** Checks if any containers are running in privileged mode (using [Kubescape](https://hub.armo.cloud/docs/c-0057))
[**Rational & Reasoning**](../RATIONALE.md#to-check-if-there-are-any-privileged-containers-kubscape-version-privileged_containers)


## [External IPs](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/security.cr#L31)
- :heavy_check_mark: Added to CNF Test Suite in release v0.27.0
- Expectation: A CNF should not run services with external IPs

**What's tested:** Checks if the CNF has services with external IPs configured

[**Rational & Reasoning**](../RATIONALE.md#to-check-if-external-ips-are-used)


## [Root user](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/security.cr#L71)
- Expectation: Containers should not run as a [root user](https://github.com/cncf/cnf-wg/blob/best-practice-no-root-in-containers/cbpps/0002-no-root-in-containers.md)

**What's tested:** Checks if any containers are running with a root user.

[**Rational & Reasoning**](../RATIONALE.md#to-check-if-any-containers-are-running-as-a-root-user-checks-the-user-outside-the-container-that-is-running-dockerd-non_root_user)


## [Privilege escalation](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/security.cr#L156)
- Expectation: Containers should not allow [privilege escalation](https://bit.ly/C0016_privilege_escalation)

**What's tested:** Check that the allowPrivilegeEscalation field in the securityContext of each container is set to false.

[**Rational & Reasoning**](../RATIONALE.md#to-check-if-any-containers-allow-for-privilege-escalation-privilege_escalation)


## [Symlink file system](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/security.cr#L175)
- Expectation: No vulnerable K8s version being used in conjunction with the [subPath](https://bit.ly/C0058_symlink_filesystem) feature.

**What's tested:** This test checks for vulnerable K8s versions and the actual usage of the subPath feature for all Pods in the CNF.

[**Rational & Reasoning**](../RATIONALE.md#to-check-if-an-attacker-can-use-a-symlink-for-arbitrary-host-file-system-access-cve-2021-25741-symlink_file_system)


## [Application credentials](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/security.cr#L194)
- Exepectation: Application credentials should not be found in the CNFs configuration files

**What's tested:** Checks the CNF for sensitive information in environment variables, by using list of known sensitive key names. Also checks for configmaps with sensitive information.

[**Rational & Reasoning**](../RATIONALE.md#to-check-if-there-are-applications-credentials-in-configuration-files-application_credentials)


## [Host network](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/security.cr#L213)
- Expectation: The CNF should not have access to the host systems network.

**What's tested:** Checks if there is a [host network](https://bit.ly/C0041_hostNetwork) attached to any of the Pods in the CNF. 

[**Rational & Reasoning**](../RATIONALE.md#to-check-if-there-is-a-host-network-attached-to-a-pod-host_network)


## [Service account mapping](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/security.cr#L232)
- Expectation: The [automatic mapping](https://bit.ly/C0034_service_account_mapping) of service account tokens should be disabled. 

**What's tested:** Check if the CNF is using service accounts that are automatically mapped. 

[**Rational & Reasoning**](../RATIONALE.md#to-check-if-there-is-automatic-mapping-of-service-accounts-service_account_mapping)


## [Ingress and Egress blocked](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/security.cr#L335)
- Expectation: [Ingress and Egress traffic should be blocked on Pods](https://bit.ly/3bhT10s).

**What's tested:** Checks each Pod in the CNF for a defined ingress and egress policy.

[**Rational & Reasoning**](../RATIONALE.md#to-check-if-there-is-an-ingress-and-egress-policy-defined-ingress_egress_blocked)


## [Privileged container](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/security.cr#L156) 
- Expectation: Containers should not have privileged capabilities enabled.

**What's tested:** Checks if any containers have privileged capabilities. Read more at [ARMO-C0057](https://bit.ly/31iGng3)


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
- Expectation: The nodePort configuration field is not found in any of the defined containers.

**What's tested:** The nodePort not used test will look through all containers defined in the installed cnf to see if the nodePort configuration field is in use.


## [hostPort not used](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/configuration.cr#L166) 
- Expectation: The hostPort configuration field is not found in any of the defined containers. 

**What's tested:**  The hostport not used test will look through all containers defined in the installed cnf to see if the hostPort configuration field is in use.

## [Hardcoded IP addresses in K8s runtime configuration](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/configuration.cr#L213) 
- Expectation: That no hardcoded IP addresses or subnet masks are found in the Kubernetes resources for the CNF.

**What's tested:** The hardcoded ip address test will scan all the Kubernetes resources of the installed cnf to ensure that no static, hardcoded ip addresses are being used in the configuration.

## [Secrets used](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/configuration.cr#L257) 
- Expectation: The CNF is using K8s secrets for the management of sensitive data.

**What's tested:** The secrets used test will scan all the Kubernetes workload resources to see if K8s secrets are being used.

## [Immutable configmap](https://github.com/cncf/cnf-testsuite/blob/v0.27.0/src/tasks/workload/configuration.cr#L362) 
- Expectation: Immutable configmaps are being used for non-mutable data.

**What's tested:** The immutable configmap test will scan the Kubernetes resources for the CNF and see if immutable configmaps are being used.

## [Pod DNS errors](https://github.com/cncf/cnf-testsuite/blob/v0.26.0/src/tasks/workload/reliability.cr#L604)
- :heavy_check_mark: Added to CNF Test Suite in release v0.26.0
- Expectation: That the CNF dosen't crash and maintains some level of availability.

**What's tested:** This test injects chaos to disrupt dns resolution in kubernetes pods and causes loss of access to services by blocking dns resolution of hostnames/domains.



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
