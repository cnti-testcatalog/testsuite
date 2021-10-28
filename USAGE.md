# CNF Test Suite CLI Usage Documentation

### Table of Contents

- [Overview](USAGE.md#overview)
- [Syntax and Usage](USAGE.md#syntax-for-running-any-of-the-tests)
- [Common Examples](USAGE.md#common-example-commands)
- [Logging Options](USAGE.md#logging-options)
- [Compatibility Tests](USAGE.md#compatibility-tests)
- [State Tests](USAGE.md#state-tests)
- [Security Tests](USAGE.md#security-tests)
- [Microservice Tests](USAGE.md#microservice-tests)
- [Scalability Tests](USAGE.md#scalability-tests)
- [Configuration and Lifecycle Tests](USAGE.md#configuration-and-lifecycle-tests)
- [Observability Tests](USAGE.md#observability-tests)
- [Installable and Upgradeable Tests](USAGE.md#installable-and-upgradeable-tests)
- [Hardware Resources and Scheduling Tests](USAGE.md#hardware-resources-and-scheduling-tests)
- [Resilience Tests](USAGE.md#resilience-tests)
- [Platform Tests](USAGE.md#platform-tests)

### Overview

The CNF Test suite can be run in production mode (using an executable) or in developer mode (using [crystal lang directly](INSTALL.md#source-install)). See the [pseudo code documentation](PSEUDO-CODE.md) for examples of how the internals of WIP tests might work.

### Syntax for running any of the tests

```
# Production mode
./cnf-testsuite <testname>

# Developer mode
crystal src/cnf-testsuite.cr <testname>
```

:star: \*Note: All usage commands in this document will use the production (binary executable) syntax unless otherwise stated.

- :heavy_check_mark: indicates implemented into stable release
- :bulb: indicates Proof of Concept
- :memo: indicates To Do
- :x: indicates WARNINGS\*

### Results Output

- :heavy_check_mark: PASSED indicates it meets best practice, positive points given.
- :heavy_multiplication_x: SKIPPED indicates the test was skipped (output should provide a reason), no points given.
- :x: FAILED indicates the test failed, negative points given.

---

### Common Example Commands

#### Building the executable

This is the command to build the binary executable if in developer mode or using the source install method ([requires crystal](INSTALL.md#source-install)):

```
crystal build src/cnf-testsuite.cr
```

#### Validating a cnf-testsuite.yml file:

```
./cnf-testsuite validate_config cnf-config=[PATH_TO]/cnf-testsuite.yml
```

#### Running all of the platform and workload tests:

```
./cnf-testsuite all cnf-config=<path_to_your_config_file>/cnf-testsuite.yml
```

#### Running all of the tests (including proofs of concepts)

```
./cnf-testsuite all poc cnf-config=<path_to_your_config_file>/cnf-testsuite.yml
```

#### Running all of the workload tests

```
crystal src/cnf-testsuite.cr workload
cnf-config=<path_to_your_config_file>/cnf-testsuite.yml
```

#### Running all of the platform or workload tests independently:

##### Run platform only tests:

```
./cnf-testsuite platform
```

##### Run workload only tests:

```
./cnf-testsuite workload
```

#### Get available options and to see all available tests from command line:

```
./cnf-testsuite help
```

#### Clean up the CNF Test Suite, the K8s cluster, and upstream projects:

```
./cnf-testsuite cleanup
```

---

### Logging Options

#### Update the loglevel from command line:

```
# cmd line
./cnf-testsuite -l debug test
```

#### If in developer mode, make sure to use - - if running from source:

```
crystal src/cnf-testsuite.cr -- -l debug test
```

#### You can also use env var for logging:

```
LOGLEVEL=DEBUG ./cnf-testsuite test
```

:star: Note: When setting log level, the following is the order of precedence:

1. CLI or Command line flag
2. Environment variable
3. CNF-Testsuite [Config file](config.yml)

##### Verbose Option

Also setting the verbose option for many tasks will add extra output to help with debugging

```
./cnf-testsuite test_name verbose
```

#### Running The Linter in Developer Mode

See https://github.com/crystal-ameba/ameba for more details. Follow the [INSTALL](INSTALL.md) guide starting at the [Source Install](INSTALL.md#source-install) for more details running cnf-testsuite in developer mode.

```
shards install # only for first install
crystal bin/ameba.cr
```

---

### Compatibility Tests

#### :heavy_check_mark: To run all of the compatibility tests

```
./cnf-testsuite compatibility
```

<details> <summary>Details for Compatibility Tests To Do's</summary>
<p>

#### :memo: (To Do) To check of the CNF's CNI plugin accepts valid calls from the [CNI specification](https://github.com/containernetworking/cni/blob/master/SPEC.md)

```
crystal src/cnf-testsuite.cr cni_spec
```

#### :memo: (To Do) To check for the use of alpha K8s API endpoints

```
crystal src/cnf-testsuite.cr api_snoop_alpha
```

#### :memo: (To Do) To check for the use of beta K8s API endpoints

```
crystal src/cnf-testsuite.cr api_snoop_beta
```

#### :memo: (To Do) To check for the use of generally available (GA) K8s API endpoints

```
crystal src/cnf-testsuite.cr api_snoop_general_apis
```

</p>
</details>

---

### State Tests

#### :heavy_check_mark: To run all of the state tests

```
./cnf-testsuite state
```

#### :heavy_check_mark: To test if the CNF uses a volume host path

```
./cnf-testsuite volume_hostpath_not_found
```

#### :heavy_check_mark: To test if the CNF uses local storage

```
./cnf-testsuite no_local_volume_configuration
```

<details> <summary>Details for State Tests To Do's</summary>
<p>

#### :memo: (To Do) To test if the CNF responds properly [when being restarted](//https://github.com/litmuschaos/litmus)

```
crystal src/cnf-testsuite.cr reset_cnf
```

#### :memo: (To Do) To test if, when parent processes are restarted, the [child processes](https://github.com/falcosecurity/falco) are [reaped](https://github.com/draios/sysdig-inspect)

```
crystal src/cnf-testsuite.cr check_reaped
```

</p>
</details>

---

### Security Tests

#### :heavy_check_mark: To run all of the security tests

```
./cnf-testsuite security
```

#### :heavy_check_mark: To check if any containers are running in [privileged mode](https://github.com/open-policy-agent/gatekeeper)

```
./cnf-testsuite privileged
```

 #### :heavy_check_mark: To check if any containers are running as a [root user](https://github.com/cncf/cnf-wg/blob/best-practice-no-root-in-containers/cbpps/0002-no-root-in-containers.md)

```
./cnf-testsuite non_root_user
```

 #### :heavy_check_mark: To check if any containers allow for [privilege escalation](https://bit.ly/3zUimHR)

```
./cnf-testsuite privilege_escalation
```

 #### :heavy_check_mark: To check if an attacker can use a [symlink](https://bit.ly/3zUimHR) for arbitrary host file system access 

```
./cnf-testsuite symlink_file_system
```

 #### :heavy_check_mark: To check if there are application credentials in [configuration files](https://bit.ly/3zUimHR) for arbitrary host file system access 

```
./cnf-testsuite application_credentials
```
 
 #### :heavy_check_mark: To check if there is a [host network attached to a pod](https://bit.ly/3zUimHR)

```
./cnf-testsuite host_network
```
 #### :heavy_check_mark: To check if there are [service accounts that are automatically mapped](https://bit.ly/3zUimHR)

```
./cnf-testsuite service_account_mapping
```

#### :heavy_check_mark: To check if there is an [ingress and egress policy defined](https://bit.ly/3bhT10s).
<details> <summary>Details for ingress_egress_blocked test</summary>
<p>

<b>ingress_egress_blocked: </b> Network policies control traffic flow between Pods, namespaces, and external IP addresses. By default, no network policies are applied to Pods or namespaces, resulting in unrestricted ingress and egress traffic within the Pod network. Pods become isolated through a network policy that applies to the Pod or the Pod’s namespace. Once a Pod is selected in a network policy, it rejects any connections that are not specifically allowed by any applicable policy object.Administrators should use a default policy selecting all Pods to deny all ingress and egress traffic and ensure any unselected Pods are isolated. Additional policies could then relax these restrictions for permissible connections.(For ARMO runtime needs to add exception). See more at [Armo's C-0030 doc on ingress egress blocked details](https://bit.ly/3bhT10s).

<b>Remediation Steps: </b> By default, you should disable or restrict Ingress and Egress traffic on all pods.

</details>

```
./cnf-testsuite ingress_egress_blocked
```

<details> <summary>Details for Security Tests To Do's</summary>
<p>

#### :memo: (To Do) To check if there are any [shells running in the container](https://github.com/open-policy-agent/gatekeeper)

```
crystal src/cnf-testsuite.cr shells
```

#### :memo: (To Do) To check if there are any [protected directories](https://github.com/open-policy-agent/gatekeeper) or files that are accessed from within the container

```
crystal src/cnf-testsuite.cr protected_access
```

</p>
</details>

---

### Microservice Tests

#### :heavy_check_mark: To run all of the microservice tests

```
./cnf-testsuite microservice
```

#### :heavy_check_mark: To check if the CNF has a reasonable image size

```
./cnf-testsuite reasonable_image_size
```

#### :heavy_check_mark: To check if the CNF have a reasonable startup time

```
./cnf-testsuite reasonable_startup_time destructive
```

#### :heavy_check_mark: To check if the CNF has multiple process types within one container

```
./cnf-testsuite single_process_type
```

---

### Scalability Tests

#### :heavy_check_mark: To run all of the scalability tests

```
./cnf-testsuite scalability
```

#### :heavy_check_mark: To test the [increasing and decreasing of capacity](https://kubernetes.io/docs/reference/kubectl/cheatsheet/#scaling-resources)

<details> <summary>Details for increasing and decreasing of capacity</summary>
<p>

<b>increase_decrease_capacity test:</b> HPA (horizonal pod autoscale) will autoscale replicas to accommodate when there is an increase of CPU, memory or other configured metrics to prevent disruption by allowing more requests by balancing out the utilisation across all of the pods.

Decreasing replicas works the same as increase but rather scale down the number of replicas when the traffic decreases to the number of pods that can handle the requests.

You can read more about horizonal pod autoscaling to create replicas [here](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/).

<b>Remediation for failing this test:</b>

Check out the kubectl docs for how to [manually scale your cnf.](https://kubernetes.io/docs/reference/kubectl/cheatsheet/#scaling-resources)

Also here is some info about [things that could cause failures.](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#failed-deployment)

</p>
</details>

```
./cnf-testsuite increase_decrease_capacity
```

<details> <summary>Details for Scalability Tests To Do's</summary>
<p>

#### :memo: (To Do) To test small scale autoscaling

```
crystal src/cnf-testsuite.cr small_autoscaling
```

#### :memo: (To Do) To test [large scale autoscaling](https://github.com/cncf/cnf-testbed)

```
crystal src/cnf-testsuite.cr large_autoscaling
```

#### :memo: (To Do) To test if the CNF responds to [network](https://github.com/alexei-led/pumba) [chaos](https://github.com/worstcase/blockade)

```
crystal src/cnf-testsuite.cr network_chaos
```

#### :memo: (To Do) To test if the CNF control layer uses [external retry logic](https://github.com/envoyproxy/envoy)

```
crystal src/cnf-testsuite.cr external_retry
```

</p>
</details>

---

### Configuration and Lifecycle Tests

#### :heavy_check_mark: To run all of the configuration and lifecycle tests

```
./cnf-testsuite configuration_lifecycle
```

#### :heavy_check_mark: To test if there are versioned tags on all images using OPA Gatekeeper

```
./cnf-testsuite versioned_tag
```

#### :heavy_check_mark: To test if there is a liveness entry in the Helm chart

```
./cnf-testsuite liveness
```

##### :heavy_check_mark: To test if there is a readiness entry in the Helm chart

```
./cnf-testsuite readiness
```

#### :heavy_check_mark: To test if there are any (non-declarative) hardcoded IP addresses or subnet masks

```
./cnf-testsuite ip_addresses
```

#### :heavy_check_mark: To test if there are node ports used in the service configuration

```
./cnf-testsuite nodeport_not_used
```

#### :heavy_check_mark: To test if there are host ports used in the service configuration

```
./cnf-testsuite hostport_not_used
```

#### :heavy_check_mark: To test if there are any (non-declarative) hardcoded IP addresses or subnet masks in the K8s runtime configuration

```
./cnf-testsuite hardcoded_ip_addresses_in_k8s_runtime_configuration
```

#### :heavy_check_mark: To check if a CNF version can be downgraded through a rolling_downgrade

```
./cnf-testsuite rolling_downgrade
```

#### :heavy_check_mark: To check if a CNF version can be rolled back [rollback](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#rolling-back-a-deployment)

```
./cnf-testsuite rollback
```

#### :heavy_check_mark: To check if a CNF uses K8s secrets

```
./cnf-testsuite secrets_used
```

##Additional information##
Rules for the test:
The whole test passes if _any_ workload resource in the cnf uses a (non-exempt) secret.
If no workload resources use a (non-exempt) secret, the test is skipped.

#### :heavy_check_mark: To check if a CNF version uses [immutable configmaps](https://kubernetes.io/docs/concepts/configuration/configmap/#configmap-immutable)

```
./cnf-testsuite immutable_configmaps
```

<details> <summary>Details for Configuration and Lifecycle Tests To Do's</summary>
<p>

#### :memo: (To Do) To test if the CNF is installed with a versioned Helm v3 Chart

```
crystal src/cnf-testsuite.cr versioned_helm_chart
```

#### :memo: (To Do) Test starting a container without mounting a volume that has configuration files

```
crystal src/cnf-testsuite.cr no_volume_with_configuration
```

#### :memo: (To Do) To test if the CNF responds properly [when being restarted](//https://github.com/litmuschaos/litmus)

```
crystal src/cnf-testsuite.cr reset_cnf
```

#### :memo: (To Do) To test if, when parent processes are restarted, the [child processes](https://github.com/falcosecurity/falco) are [reaped](https://github.com/draios/sysdig-inspect)

```
crystal src/cnf-testsuite.cr check_reaped
```

</p>
</details>

---

### Observability Tests

#### :heavy_check_mark: To run all observability tests

```
./cnf-testsuite observability
```

<details> <summary>Details for Observability Tests To Do's</summary>
<p>

#### :memo: (To Do) Test if there traffic to Fluentd

```
crystal src/cnf-testsuite.cr fluentd_traffic
```

#### :memo: (To Do) Test if there is traffic to Jaeger

```
crystal src/cnf-testsuite.cr jaeger_traffic
```

#### :memo: (To Do) Test if there is traffic to Prometheus

```
crystal src/cnf-testsuite.cr prometheus traffic
```

#### :memo: (To Do) Test if tracing calls are compatible with [OpenTelemetry](https://opentracing.io/)

```
crystal src/cnf-testsuite.cr opentelemetry_compatible
```

#### :memo: (To Do) Test are if the monitoring calls are compatible with [OpenMetric](https://github.com/OpenObservability/OpenMetrics)

```
crystal src/cnf-testsuite.cr openmetric_compatible
```

</p>
</details>

---

### Installable and Upgradeable Tests

#### :heavy_check_mark: To run all installability tests

```
./cnf-testsuite installability
```

#### :heavy_check_mark: Test if the Helm chart is published

```
./cnf-testsuite helm_chart_published
```

#### :heavy_check_mark: Test if the [Helm chart is valid](https://github.com/helm/chart-testing))

```
./cnf-testsuite helm_chart_valid
```

#### :heavy_check_mark: Test if the Helm deploys

Use a cnf-testsuite.yml to manually call helm_deploy, e.g.:
Copy your CNF into the `cnfs` directory:

```
cp -rf <your-cnf-directory> cnfs/<your-cnf-directory>
```

Now run the test:

```
./cnf-testsuite helm_deploy destructive cnfs/<your-cnf-directory>/cnf-testsuite.yml
```

#### :heavy_check_mark: Test if the install script uses [Helm v3](https://github.com/helm/)

```
./cnf-testsuite install_script_helm
```

#### :heavy_check_mark: To test if the CNF can perform a [rolling update](https://kubernetes.io/docs/tasks/run-application/rolling-update-replication-controller/)

```
./cnf-testsuite rolling_update
```

---

### Hardware Resources and Scheduling Tests

#### :heavy_check_mark: Run all hardware resources and scheduling tests

```
crystal src/cnf-testsuite.cr hardware_and_scheduling

```

<details> <summary>Details for Hardware and Scheduling Tests To Do's</summary>
<p>

#### :memo: (To Do) Test if the CNF is accessing hardware in its configuration files

```
crystal src/cnf-testsuite.cr static_accessing_hardware
```

#### :memo: (To Do) Test if the CNF is accessing hardware directly during run-time (e.g. accessing the host /dev or /proc from a mount)

```
crystal src/cnf-testsuite.cr dynamic_accessing_hardware
```

#### :memo: (To Do) Test if the CNF is accessing hugepages directly instead of via [Kubernetes resources](https://github.com/cncf/cnf-testbed/blob/c4458634deca5e8ab73adf118eedde32904c8458/examples/use_case/external-packet-filtering-on-k8s-nsm-on-packet/gateway.yaml#L29)

```
crystal src/cnf-testsuite.cr direct_hugepages
```

#### :memo: (To Do) Test if the CNF Testbed performance output shows adequate throughput and sessions using the [CNF Testbed](https://github.com/cncf/cnf-testbed) (vendor neutral) hardware environment

```
crystal src/cnf-testsuite.cr performance
```

</p>
</details>

---

### Resilience Tests

#### :heavy_check_mark: To run all resilience tests

```
./cnf-testsuite resilience
```

#### :heavy_check_mark: Test if the CNF crashes when network loss occurs

```
./cnf-testsuite chaos_network_loss
```

#### :heavy_check_mark: Test if the CNF crashes under high CPU load

```
./cnf-testsuite chaos_cpu_hog
```

#### :heavy_check_mark: Test if the CNF restarts after container is killed

```
./cnf-testsuite chaos_container_kill
```

#### :heavy_check_mark: Test if the CNF crashes when network latency occurs

<details> <summary>Details for litmus pod network latency experiment</summary>
<p>

<b>Pod Network Latency:</b> As we know network latency can have a significant impact on the overall performance of the application the network outages can cause a range of failures for applications that can severely impact user/customers with downtime. This chaos experiment allows you to see the impact of latency traffic to your application using the traffic control (tc) process with netem rules to add egress delays and test how your service behaves when you are unable to reach one of your dependencies, internal or external.

[This experiment](https://docs.litmuschaos.io/docs/pod-network-latency/) causes network degradation without the pod being marked unhealthy/unworthy of traffic by kube-proxy (unless you have a liveness probe of sorts that measures latency and restarts/crashes the container). The idea of this experiment is to simulate issues within your pod network OR microservice communication across services in different availability zones/regions etc.

Mitigation (in this case keep the timeout i.e., access latency low) could be via some middleware that can switch traffic based on some SLOs m parameters. If such an arrangement is not available the next best thing would be to verify if such degradation is highlighted via notification/alerts etc, so the admin/SRE has the opportunity to investigate and fix things. Another utility of the test would be to see the extent of impact caused to the end-user OR the last point in the app stack on account of degradation in access to a downstream/dependent microservice. Whether it is acceptable OR breaks the system to an unacceptable degree. The experiment provides DESTINATION_IPS or DESTINATION_HOSTS so that you can control the chaos against specific services within or outside the cluster.

The applications may stall or get corrupted while they wait endlessly for a packet. The experiment limits the impact (blast radius) to only the traffic you want to test by specifying IP addresses or application information. This experiment will help to improve the resilience of your services over time.

</p>
</details>

```
./cnf-testsuite pod_network_latency
```

#### :heavy_check_mark: Test if the CNF crashes when disk fill occurs

<details> <summary> Details for litmus disk fill experiment</summary>
<p>

<b>Disk-Fill(Stress-Chaos):</b> Disk Pressure is another very common and frequent scenario we find in Kubernetes applications that can result in the eviction of the application replica and impact its delivery. Such scenarios can still occur despite whatever availability aids K8s provides. These problems are generally referred to as "Noisy Neighbour" problems.

[Stressing the disk](https://litmuschaos.github.io/litmus/experiments/categories/pods/disk-fill/) with continuous and heavy IO for example can cause degradation in reads written by other microservices that use this shared disk for example modern storage solutions for Kubernetes to use the concept of storage pools out of which virtual volumes/devices are carved out. Another issue is the amount of scratch space eaten up on a node which leads to the lack of space for newer containers to get scheduled (Kubernetes too gives up by applying an "eviction" taint like "disk-pressure") and causes a wholesale movement of all pods to other nodes. Similarly with CPU chaos, by injecting a rogue process into a target container, we starve the main microservice process (typically PID 1) of the resources allocated to it (where limits are defined) causing slowness in application traffic or in other cases unrestrained use can cause the node to exhaust resources leading to the eviction of all pods. So this category of chaos experiment helps to build the immunity on the application undergoing any such stress scenario.

</p>
</details>

```
./cnf-testsuite disk_fill
```

#### :heavy_check_mark: Test if the CNF crashes when pod delete occurs

<details> <summary>Details for litmus pod delete experiment</summary> 
<p>

<b>Pod Delete:</b> In a distributed system like Kubernetes, likely, your application replicas may not be sufficient to manage the traffic (indicated by SLIs) when some of the replicas are unavailable due to any failure (can be system or application) the application needs to meet the SLO(service level objectives) for this, we need to make sure that the applications have a minimum number of available replicas. One of the common application failures is when the pressure on other replicas increases then to how the horizontal pod autoscaler scales based on observed resource utilization and also how much PV mount takes time upon rescheduling. The other important aspects to test are the MTTR for the application replica, re-elections of leader or follower like in Kafka application the selection of broker leader, validating minimum quorum to run the application for example in applications like percona, resync/redistribution of data.

[This experiment](https://litmuschaos.github.io/litmus/experiments/categories/pods/pod-delete/) helps to simulate such a scenario with forced/graceful pod failure on specific or random replicas of an application resource and checks the deployment sanity (replica availability & uninterrupted service) and recovery workflow of the application.

</p>
</details>

```
./cnf-testsuite pod_delete
```

#### :heavy_check_mark: Test if the CNF crashes when pod memory hog occurs

<details> <summary>Details for litmus pod memory hog experiment</summary>
<p>

Memory usage within containers is subject to various constraints in Kubernetes. If the limits are specified in their spec, exceeding them can cause termination of the container (due to OOMKill of the primary process, often pid 1) - the restart of the container by kubelet, subject to the policy specified. For containers with no limits placed, the memory usage is uninhibited until such time as the Node level OOM Behaviour takes over. In this case, containers on the node can be killed based on their oom_score and the QoS class a given pod belongs to (bestEffort ones are first to be targeted). This eval is extended to all pods running on the node - thereby causing a bigger blast radius. 

The [pod-memory hog](https://litmuschaos.github.io/litmus/experiments/categories/pods/pod-memory-hog/) experiment launches a stress process within the target container - which can cause either the primary process in the container to be resource constrained in cases where the limits are enforced OR eat up available system memory on the node in cases where the limits are not specified. 

</p>
</details>


```
./cnf-testsuite pod_memory_hog
```

#### :heavy_check_mark: Test if the CNF crashes when pod io stress occurs

<details> <summary>Details for litmus pod io stress experiment</summary>
<p>

Sressing the disk with continuous and heavy IO can cause degradation in reads/ writes byt other microservices that use this shared disk.  For example modern storage solutions for Kubernetes use the concept of storage pools out of which virtual volumes/devices are carved out.  Another issue is the amount of scratch space eaten up on a node which leads to  the lack of space for newer containers to get scheduled (kubernetes too gives up by applying an "eviction" taint like "disk-pressure") and causes a wholesale movement of all pods to other nodes.

[This experiment](https://litmuschaos.github.io/litmus/experiments/categories/pods/pod-io-stress/) is also useful in determining the performance of the storage device used.  
</p>
</details>

```
./cnf-testsuite pod_io_stress
```

#### :heavy_check_mark: Test if the CNF crashes when pod network corruption occurs

```
./cnf-testsuite pod_network_corruption
```

---

#### :heavy_check_mark: Test if the CNF crashes when pod network duplication occurs

```
./cnf-testsuite pod_network_duplication
```

#### :heavy_check_mark: Test if the CNF crashes when node drain occurs

```
./cnf-testsuite node_drain
```

### Platform Tests

#### :heavy_check_mark: Run all platform tests

```
./cnf-testsuite platform
```

#### :heavy_check_mark: Run the K8s conformance tests

```
./cnf-testsuite  k8s_conformance
```

#### :heavy_check_mark: To test if Cluster API is enabled on the platform and manages a node

```
./cnf-testsuite clusterapi_enabled
```

### Hardware and Scheduling Platform Tests

#### :heavy_check_mark: Run All platform harware and scheduling tests

```
./cnf-testsuite  platform:hardware_and_scheduling
```

#### :heavy_check_mark: Run runtime compliance test

```
./cnf-testsuite platform:oci_compliant
```

### Observability Platform Tests

##### :bulb: (PoC) Run All platform observability tests

```
./cnf-testsuite platform:observability poc
```

### Resilience Platform Tests

##### :bulb: (PoC) Run All platform resilience tests

```
./cnf-testsuite platform:resilience poc
```

##### :x: :bulb: (PoC) Run node failure test. WARNING this is a destructive test and will reboot your _host_ node!

##### Do not run this unless you have completely separate cluster, e.g. development or test cluster.

```
./cnf-testsuite platform:node_failure poc destructive
```
### Security Platform Tests
##### :heavy_check_mark: Run All platform security tests

```
./cnf-testsuite platform:security 
```
 #### :heavy_check_mark: To check if [cluster admin is bound to a pod](https://bit.ly/3zUimHR)

```
./cnf-testsuite platform:cluster_admin
```
 #### :heavy_check_mark: To check if [the control plane is hardened](https://bit.ly/3zUimHR)

```
./cnf-testsuite platform:control_plane_hardening
```

#### :heavy_check_mark: To check if dashboard is exposed

<details> <summary>Details for platform:exposed_dashboard</summary>
<p>

<b>Exposed Dashboard:</b> If Kubernetes dashboard is exposed externally in Dashboard versions before 2.01, it will allow unauthenticated remote management of the cluster. By default, the dashboard exposes an internal endpoint (ClusterIP service). While the [NSA and CISA’s K8s Hardening guide](https://bit.ly/3zUimHR) does not directly address the dashboard exposure it does go over related areas like the Control plane API. See more details in Kubescape documentation: [C-0047 - Exposed dashboard](https://hub.armo.cloud/docs/c-0047)

<b>Remediation for failing this test: </b>

Update dashboard version to v2.0.1 or above.

</p>
</details>

```
./cnf-testsuite platform:exposed_dashboard
```


