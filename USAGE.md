# CNF Test Suite CLI Usage Documentation

### Table of Contents

- [Overview](USAGE.md#overview)
- [Syntax and Usage](USAGE.md#syntax-for-running-any-of-the-tests)
- [Common Examples](USAGE.md#common-example-commands)
- [Logging Options](USAGE.md#logging-options)
- [Workload Tests](USAGE.md#workload-tests)
  - [Compatibility, Installability, and Upgradability Tests](USAGE.md#compatibility-installability-and-upgradability-tests)
  - [Microservice Tests](USAGE.md#microservice-tests)
  - [State Tests](USAGE.md#state-tests)
  - [Reliability, Resilience and Availability Tests](USAGE.md#reliability-resilience-and-availability)
  - [Observability and Diagnostic Tests](USAGE.md#observability-and-diagnostic-tests)
  - [Security Tests](USAGE.md#security-tests)
  - [Configuration Tests](USAGE.md#configuration-tests)
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
- ⏭ SKIPPED indicates the test was skipped (output should provide a reason), no points given.
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

##### Run workload only tests:

```
./cnf-testsuite workload
```

##### Run platform only tests (long running):

```
./cnf-testsuite platform
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
### Workload Tests

#### Compatibility, Installability, and Upgradability Tests

##### :heavy_check_mark: To run all of the compatibility tests

```
./cnf-testsuite compatibility
```

##### :heavy_check_mark: To test the [increasing and decreasing of capacity](https://kubernetes.io/docs/reference/kubectl/cheatsheet/#scaling-resources)

<details> <summary>Details for increasing and decreasing of capacity</summary>
<p>

<b>increase_decrease_capacity test:</b> HPA (horizonal pod autoscale) will autoscale replicas to accommodate when there is an increase of CPU, memory or other configured metrics to prevent disruption by allowing more requests 
by balancing out the utilisation across all of the pods.

Decreasing replicas works the same as increase but rather scale down the number of replicas when the traffic decreases to the number of pods that can handle the requests.

You can read more about horizonal pod autoscaling to create replicas [here](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/).

<b>Read about the [rationale](RATIONALE.md#to-test-the-increasing-and-decreasing-of-capacity-increase_decrease_capacity) on why this gets tested.</b>

<b>Remediation for failing this test:</b>

Check out the kubectl docs for how to [manually scale your cnf.](https://kubernetes.io/docs/reference/kubectl/cheatsheet/#scaling-resources)

Also here is some info about [things that could cause failures.](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#failed-deployment)

</p>
</details>

##### To run the increase_capacity test individually:

```
./cnf-testsuite increase_capacity
```

##### To run the decrease_capacity test individually:

```
./cnf-testsuite decrease_capacity
```

##### To run both increase and decrease tests, you can use the alias command that calls them both:
```
./cnf-testsuite increase_decrease_capacity
```

##### :heavy_check_mark: Test if the Helm chart is published

<details><summary>Details on helm_chart_published:</summary>
<p>

<b>helm_chart_published description:</b> Best practice for published helm charts allow management from the registry and client tools rather than manually from source.

<b>Read the [rationale](RATIONALE.md#test-if-the-helm-chart-is-published-helm_chart_published) behind this test.</b>

<b>Remediation:</b> Make sure your CNF helm charts are published.

</p>
</details>

```
./cnf-testsuite helm_chart_published
```

##### :heavy_check_mark: Check if the [Helm chart is valid](https://github.com/helm/chart-testing)

<details><summary>Details on helm_chart_valid test:</summary>
<p>

<b>helm_chart_valid description:</b> Best practice is to ensure that helm charts are in valid formats.

<b>Read the [rationale](RATIONALE.md#test-if-the-helm-chart-is-valid-helm_chart_valid) behind this test.</b>

<b>Remediation:</b> Make sure your helm charts pass lint tests.

</p>
</details>

```
./cnf-testsuite helm_chart_valid
```

##### :heavy_check_mark: Test if the Helm deploys

<details><summary>Details on helm_deploy:</summary>
<p>

<b>helm_deploy description:</b> All helm charts should be deployable.

<b>Read the [rationale](RATIONALE.md#test-if-the-helm-deploys-helm_deploy) behind this test.</b>

<b>Remediation:</b> Make sure your helm charts are valid and can be deployed to clusters.

</p>
</details>

Use a cnf-testsuite.yml to manually call helm_deploy, e.g.:
Copy your CNF into the `cnfs` directory:

```
cp -rf <your-cnf-directory> cnfs/<your-cnf-directory>
```

Now run the test:

```
./cnf-testsuite helm_deploy destructive cnfs/<your-cnf-directory>/cnf-testsuite.yml
```

##### :heavy_check_mark: To check if the install script uses [Helm v3](https://github.com/helm/)

<details><summary>Details for install_script_helm:</summary>
<p>

<b>install_script_helm details:</b> This checks if you are using helm v3 which has vast improvements and less dependencies than v2 (eg. tiller).

<b>Read the [rationale](RATIONALE.md#test-if-cnfthe-install-script-uses-helm-v3-install_script_helm) about this test.</b>

<b>Remediation:</b> Update your helm charts and scripts to be compatible with the latest helm v3 or later.

</p>
</details> 

```
./cnf-testsuite install_script_helm
```

##### :heavy_check_mark: To test if the CNF can perform a [rolling update](https://kubernetes.io/docs/tutorials/kubernetes-basics/update/update-intro/)

<details><summary>Details on rolling_update:</summary>
<p>

<b>rolling_update description:</b> Rollling updates allow for applications to be updated and promoted between environments without downtime.

<b>Read the [rationale](RATIONALE.md#to-test-if-the-cnf-can-perform-a-rolling-update-rolling_update) behind this test.</b>

<b>Remediation:</b> Best practice should allow your CNF and applications should be able to perform rolling updates without downtime.

</p>
</details>

```
./cnf-testsuite rolling_update
```

##### :heavy_check_mark: To check if a CNF version can be downgraded through a rolling_version_change

<details><summary>Details for rolling_version_change:</summary>
<p>

<b>rolling_version_change description:</b>

<b>Read the [rationale](RATIONALE.md#to-check-if-a-cnf-version-can-be-downgraded-through-a-rolling_version_change-rolling_version_change) for this test.<b/>

<b>Remediation:</b> Applications or CNFs should have the ability to downgrade based on the version tag. 

</p>
</details>

```
./cnf-testsuite rolling_version_change
```

##### :heavy_check_mark: To check if a CNF version can be downgraded through a rolling_downgrade

<details><summary>Details on rolling_downgrade:</summary>
<p>

<b>rolling_downgrade description:</b> Rolling downgrade allows for applications to be downgraded in the event that the newest or latest version encounters issues, eg bug, incompatiblility, etc.

<b>Read the [rationale](RATIONALE.md#to-check-if-a-cnf-version-can-be-downgraded-through-a-rolling_downgrade-rolling_downgrade) behind this test.</b>

<b>Remediation:</b> Best practice should allow your CNF and applications should be able to perform rolling downgradse without downtime.

</p>
</details>

```
./cnf-testsuite rolling_downgrade
```

##### :heavy_check_mark: To check if a CNF version can be rolled back [rollback](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#rolling-back-a-deployment)

<details><summary>Details on rollback:</summary>
<p>

<b>rollback description:</b> Rollback allows for the rollback of an application when it becomes unstable, like crash looping, etc.

<b>Read the [rationale](RATIONALE.md#to-check-if-a-cnf-version-can-be-rolled-back-rollback) behind this test.</b>

<b>Remediation:</b> Best practice should allow your CNF and applications to perform automatic rollbacks.

</p>
</details>

```
./cnf-testsuite rollback
```

##### :heavy_check_mark: To check if the CNF is compatible with different CNIs
<details> <summary>Details for CNI Compatibility Tests</summary>
<p>

<b>CNI Compatible Tests:</b> Best practice states a good CNF should be compatible with multiple and different CNIs (Container Network Interface). The CNI handles the container network for the container network namespace, along with management of IP Addresses through IPAM plug-in among other networking needs and requirements. You can read more about CNIs for kubernetes with their list of [compatible CNIs](https://bit.ly/cni-compatible-k8s-doc). 

<b>What's Tested:</b> This test will install temporary kind clusters to test your CNF using Calico and Cilium CNIs.

<b>Read the [rationale](RATIONALE.md#to-check-if-the-cnf-is-compatible-with-different-cnis-cni_compatibility) behind this test.</b>

<b>Remediation:</b> To mitigate this issue, make sure your CNF is compatible with Calico, Cilium and other available CNIs.
</p>

</details>

```
./cnf-testsuite cni_compatible
```

##### :bulb: (PoC) To check if a CNF uses Kubernetes alpha APIs

<details> <summary>Details for Kubernetes alpha APIs test</summary>
<p>

<b>Kubernetes alpha APIs:</b> It is considered a best-practice for resources to not use [Kubernetes alpha APIs](https://bit.ly/apisnoop).

<b>Read the [rationale](RATIONALE.md#poc-to-check-if-a-cnf-uses-kubernetes-alpha-apis-alpha_k8s_apis-alpha_k8s_apis) behind this test.</b>

<b>Remediation Steps:</b> Make sure applications and CNFs are not using Kubernetes alpha APIs. You can learn more about Kubernetes API versioning [here](https://bit.ly/k8s_api).
</p>

</details>

```
./cnf-testsuite alpha_k8s_apis
```

<details> <summary>Details for Compatibility, Installability and Upgradability Tests To Do's</summary>
<p>

#### :memo: (To Do) To check of the CNF's CNI plugin accepts valid calls from the [CNI specification](https://github.com/containernetworking/cni/blob/master/SPEC.md)

```
crystal src/cnf-testsuite.cr cni_spec
```

#### :memo: (To Do) To check for the use of beta K8s API endpoints

```
crystal src/cnf-testsuite.cr api_snoop_beta
```

#### :memo: (To Do) To check for the use of generally available (GA) K8s API endpoints

```
crystal src/cnf-testsuite.cr api_snoop_general_apis
```

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


#### Microservice Tests

##### :heavy_check_mark: To run all of the microservice tests

```
./cnf-testsuite microservice
```

##### :heavy_check_mark: To check if the CNF has a reasonable image size
<details> <summary>Details for reasonable image size</summary>
<p>

<b>Reasonable Image Size:</b> 

<b>Read the [rationale](RATIONALE.md#to-check-if-the-cnf-has-a-reasonable-image-size-reasonable_image_size) behind this test.</b>

<b>Remediation:</b> TBD
</p>

</details>

```
./cnf-testsuite reasonable_image_size
```

##### :heavy_check_mark: To check if the CNF have a reasonable startup time
<details> <summary>Details for reasonable startup time</summary>
<p>

<b>Reasonable Startup Time:</b> 

<b>Read the [rationale](RATIONALE.md#to-check-if-the-cnf-have-a-reasonable-startup-time-reasonable_startup_time) behind this test.</b>

<b>Remediation:</b> TBD
</p>

</details>

```
./cnf-testsuite reasonable_startup_time destructive
```

##### :heavy_check_mark: To check if the CNF is using only a single process type per container
<details> <summary>Details for single process type</summary>
<p>

<b>Single process type:</b> 

<b>Read the [rationale](https://github.com/cncf/cnf-testsuite/blob/main/RATIONALE.md#to-check-if-the-cnf-has-multiple-process-types-within-one-container-single_process_type) behind this test.</b>

<b>Remediation:</b> TBD
</p>

</details>

```
./cnf-testsuite single_process_type
```

#### :heavy_check_mark: To check if the CNF exposes any of its containers as a service

<details> <summary>Details for the service discovery test</summary>
<p>

<b>Service discovery:</b> For microservices to be accessible to other applications in the cluster, they should be exposed via a Service.

<b>Read the [rationale](RATIONALE.md#to-check-if-the-cnf-exposes-any-of-its-containers-as-a-service-service_discovery-service_discovery) behind this test.</b>

<b>Remediation Steps:</b> Make sure the CNF exposes any of its containers as a Kubernetes Service. You can learn more about Kubernetes Service [here](https://kubernetes.io/docs/concepts/services-networking/service/).
</p>

</details>

```
./cnf-testsuite service_discovery
```

#### :heavy_check_mark: To check if the CNF has multiple microservices that share a database 

<details> <summary>Details for the shared database test</summary>
<p>

<b>Shared Database:</b> Microservices should not share a database with one another.

<b>Read the [rationale](RATIONALE.md#to-check-if-the-cnf-uses-a-shared-database-shared_database) behind this test.</b>

<b>Remediation Steps:</b> Make sure the CNF microservices do not share a database [here](https://martinfowler.com/bliki/IntegrationDatabase.html).
</p>

</details>

```
./cnf-testsuite shared_database 
```

#### State Tests

##### :heavy_check_mark: To run all of the state tests

```
./cnf-testsuite state
```

##### :heavy_check_mark: Test if the CNF is available when node drain and rescheduling occurs.  All configuration should be stateless.
<details> <summary>Details for node drain</summary>
<p>

<b>Node drain:</b> 

<b>Read the [rationale](RATIONALE.md#test-if-the-cnf-crashes-when-node-drain-occurs-node_drain) behind this test.</b>

<b>Remediation:</b> TBD
</p>

</details>

```
./cnf-testsuite node_drain
```


##### :heavy_check_mark: To test if the CNF uses a volume host path
<details> <summary>Details for volume hostpath not found</summary>
<p>

<b>Volume hostpath not found:</b> 

<b>Read the [rationale](RATIONALE.md#to-test-if-the-cnf-uses-a-volume-host-path-volume_hostpath_not_found) behind this test.</b>

<b>Remediation:</b> TBD
</p>

</details>

```
./cnf-testsuite volume_hostpath_not_found
```

##### :heavy_check_mark: To test if the CNF uses local storage
<details> <summary>Details for no local volume configuration</summary>
<p>

<b>No local volume configurattion:</b> 

<b>Read the [rationale](RATIONALE.md#to-test-if-the-cnf-uses-local-storage-no_local_volume_configuration) behind this test.</b>

<b>Remediation:</b> TBD
</p>

</details>

```
./cnf-testsuite no_local_volume_configuration
```

##### :heavy_check_mark: To test if the CNF uses elastic volumes
<details> <summary>Details for elastic volume</summary>
<p>

<b>Elastic Volume Details:</b> It's considered best practice to use elastic volumes for storage. Instead of local storage, the CNF should use elastic persistent volumes, which are available to all nodes (based on policy).

<b>Read the [rationale](RATIONALE.md#to-test-if-the-cnf-uses-elastic-volumes-elastic_volumes) behind this test.</b>

<b>Remediation Steps:</b> Setup and use elastic persistent volumes instead of local storage.
</p>

</details>


```
./cnf-testsuite elastic_volume
```
##### :heavy_check_mark: To test if the CNF uses a database with either statefulsets, elastic volumes, or both
<details> <summary>Details for Database Persistence</summary>

<p><b>Database Persistence:</b> A database may use statefulsets along with elastic volumes to achieve a high level of resiliency.  Any database in K8s should at least use elastic volumes to achieve a minimum level of resilience regardless of whether a statefulset is used.  Statefulsets without elastic volumes is not recommended, especially if it explicitly uses local storage.  The least optimal storage configuration for a database managed by K8s is local storage and no statefulsets, as this is not tolerant to node failure. 

<b>Read the [rationale](RATIONALE.md#to-test-if-the-cnf-uses-a-database-with-either-statefulsets-elastic-volumes-or-both-database_persistence) behind this test.</b>

<b>Remediation:</b> Select a database configuration that uses statefulsets and elastic storage volumes.

See more at [OpenEBS Storage Concepts](https://openebs.io/docs/concepts/basics)

</p>
</details>

```
./cnf-testsuite database_persistence 
```

#### Reliability, Resilience and Availability

##### :heavy_check_mark: To run all resilience tests

```
./cnf-testsuite resilience
```

##### :heavy_check_mark: Test if the CNF crashes when network latency occurs

<details> <summary>Details for litmus pod network latency experiment</summary>
<p>

<b>Pod Network Latency:</b> As we know network latency can have a significant impact on the overall performance of the application the network outages can cause a range of failures for applications that can severely impact user/customers with downtime. This chaos experiment allows you to see the impact of latency traffic to your application using the traffic control (tc) process with netem rules to add egress delays and test how your service behaves when you are unable to reach one of your dependencies, internal or external.

[This experiment](https://docs.litmuschaos.io/docs/pod-network-latency/) causes network degradation without the pod being marked unhealthy/unworthy of traffic by kube-proxy (unless you have a liveness probe of sorts that measures latency and restarts/crashes the container). The idea of this experiment is to simulate issues within your pod network OR microservice communication across services in different availability zones/regions etc.

Mitigation (in this case keep the timeout i.e., access latency low) could be via some middleware that can switch traffic based on some SLOs m parameters. If such an arrangement is not available the next best thing would be to verify if such degradation is highlighted via notification/alerts etc, so the admin/SRE has the opportunity to investigate and fix things. Another utility of the test would be to see the extent of impact caused to the end-user OR the last point in the app stack on account of degradation in access to a downstream/dependent microservice. Whether it is acceptable OR breaks the system to an unacceptable degree. The experiment provides DESTINATION_IPS or DESTINATION_HOSTS so that you can control the chaos against specific services within or outside the cluster.

The applications may stall or get corrupted while they wait endlessly for a packet. The experiment limits the impact (blast radius) to only the traffic you want to test by specifying IP addresses or application information. This experiment will help to improve the resilience of your services over time.

<b>Read the [rationale](RATIONALE.md#test-if-the-cnf-crashes-when-network-latency-occurs-pod_network_latency) behind this test.</b>

</p>
</details>

```
./cnf-testsuite pod_network_latency
```

##### :heavy_check_mark: Test if the CNF crashes when disk fill occurs

<details> <summary> Details for litmus disk fill experiment</summary>
<p>

<b>Disk-Fill(Stress-Chaos):</b> Disk Pressure is another very common and frequent scenario we find in Kubernetes applications that can result in the eviction of the application replica and impact its delivery. Such scenarios can still occur despite whatever availability aids K8s provides. These problems are generally referred to as "Noisy Neighbour" problems.

[Stressing the disk](https://litmuschaos.github.io/litmus/experiments/categories/pods/disk-fill/) with continuous and heavy IO for example can cause degradation in reads written by other microservices that use this shared disk for example modern storage solutions for Kubernetes to use the concept of storage pools out of which virtual volumes/devices are carved out. Another issue is the amount of scratch space eaten up on a node which leads to the lack of space for newer containers to get scheduled (Kubernetes too gives up by applying an "eviction" taint like "disk-pressure") and causes a wholesale movement of all pods to other nodes. Similarly with CPU chaos, by injecting a rogue process into a target container, we starve the main microservice process (typically PID 1) of the resources allocated to it (where limits are defined) causing slowness in application traffic or in other cases unrestrained use can cause the node to exhaust resources leading to the eviction of all pods. So this category of chaos experiment helps to build the immunity on the application undergoing any such stress scenario.

<b>Read the [rationale](RATIONALE.md#test-if-the-cnf-crashes-when-disk-fill-occurs-disk_fill) behind this test.</b>

</p>
</details>

```
./cnf-testsuite disk_fill
```

##### :heavy_check_mark: Test if the CNF crashes when pod delete occurs

<details> <summary>Details for litmus pod delete experiment</summary> 
<p>

<b>Pod Delete:</b> In a distributed system like Kubernetes, likely, your application replicas may not be sufficient to manage the traffic (indicated by SLIs) when some of the replicas are unavailable due to any failure (can be system or application) the application needs to meet the SLO(service level objectives) for this, we need to make sure that the applications have a minimum number of available replicas. One of the common application failures is when the pressure on other replicas increases then to how the horizontal pod autoscaler scales based on observed resource utilization and also how much PV mount takes time upon rescheduling. The other important aspects to test are the MTTR for the application replica, re-elections of leader or follower like in Kafka application the selection of broker leader, validating minimum quorum to run the application for example in applications like percona, resync/redistribution of data.

[This experiment](https://litmuschaos.github.io/litmus/experiments/categories/pods/pod-delete/) helps to simulate such a scenario with forced/graceful pod failure on specific or random replicas of an application resource and checks the deployment sanity (replica availability & uninterrupted service) and recovery workflow of the application.

<b>Read the [rationale](RATIONALE.md#test-if-the-cnf-crashes-when-pod-delete-occurs-pod_delete) behind this test.</b>

</p>
</details>

```
./cnf-testsuite pod_delete
```

##### :heavy_check_mark: Test if the CNF crashes when pod memory hog occurs

<details> <summary>Details for litmus pod memory hog experiment</summary>
<p>

Memory usage within containers is subject to various constraints in Kubernetes. If the limits are specified in their spec, exceeding them can cause termination of the container (due to OOMKill of the primary process, often pid 1) - the restart of the container by kubelet, subject to the policy specified. For containers with no limits placed, the memory usage is uninhibited until such time as the Node level OOM Behaviour takes over. In this case, containers on the node can be killed based on their oom_score and the QoS class a given pod belongs to (bestEffort ones are first to be targeted). This eval is extended to all pods running on the node - thereby causing a bigger blast radius. 

The [pod-memory hog](https://litmuschaos.github.io/litmus/experiments/categories/pods/pod-memory-hog/) experiment launches a stress process within the target container - which can cause either the primary process in the container to be resource constrained in cases where the limits are enforced OR eat up available system memory on the node in cases where the limits are not specified. 

<b>Read the [rationale](RATIONALE.md#test-if-the-cnf-crashes-when-pod-memory-hog-occurs-pod_memory_hog) behind this test.</b>

</p>
</details>


```
./cnf-testsuite pod_memory_hog
```

##### :heavy_check_mark: Test if the CNF crashes when pod io stress occurs

<details> <summary>Details for litmus pod io stress experiment</summary>
<p>

Sressing the disk with continuous and heavy IO can cause degradation in reads/ writes byt other microservices that use this shared disk.  For example modern storage solutions for Kubernetes use the concept of storage pools out of which virtual volumes/devices are carved out.  Another issue is the amount of scratch space eaten up on a node which leads to  the lack of space for newer containers to get scheduled (kubernetes too gives up by applying an "eviction" taint like "disk-pressure") and causes a wholesale movement of all pods to other nodes.

[This experiment](https://litmuschaos.github.io/litmus/experiments/categories/pods/pod-io-stress/) is also useful in determining the performance of the storage device used.  

<b>Read the [rationale](RATIONALE.md#test-if-the-cnf-crashes-when-pod-io-stress-occurs-pod_io_stress) behind this test.</b>

</p>
</details>

```
./cnf-testsuite pod_io_stress
```

##### :heavy_check_mark: Test if the CNF crashes when pod network corruption occurs
<details> <summary>Details for pod network corruption </summary>
<p>

<b>Pod Network Corruption:</b> 

<b>Read the [rationale](RATIONALE.md#test-if-the-cnf-crashes-when-pod-network-corruption-occurs-pod_network_corruption) behind this test.</b>

<b>Remediation:</b> TBD
</p>

</details>


```
./cnf-testsuite pod_network_corruption
```

##### :heavy_check_mark: Test if the CNF crashes when pod network duplication occurs
<details> <summary>Details for network duplication</summary>
<p>

<b>Network Duplication:</b> 

<b>Read the [rationale](RATIONALE.md#test-if-the-cnf-crashes-when-pod-network-duplication-occurs-pod_network_duplication) behind this test.</b>

<b>Remediation:</b> TBD
</p>

</details>

```
./cnf-testsuite pod_network_duplication
```

##### :heavy_check_mark: To test if there is a liveness entry in the Helm chart
<details> <summary>Details for liveness</summary>
<p>

<b>Liveness:</b> 

<b>Read the [rationale](RATIONALE.md#to-test-if-there-is-a-liveness-entry-in-the-helm-chart-liveness) behind this test.</b>

<b>Remediation:</b> TBD
</p>

</details>

```
./cnf-testsuite liveness
```

##### :heavy_check_mark: To test if there is a readiness entry in the Helm chart
<details> <summary>Details for readiness</summary>
<p>

<b>Readiness:</b> 

<b>Read the [rationale](RATIONALE.md#to-test-if-there-is-a-readiness-entry-in-the-helm-chart-readiness) behind this test.</b>

<b>Remediation:</b> TBD
</p>

</details>

```
./cnf-testsuite readiness
```

#### Observability and Diagnostic Tests

##### :heavy_check_mark: To run all observability tests

```
./cnf-testsuite observability
```

##### :heavy_check_mark: To check if logs are being sent to stdout/stderr
<details> <summary>Details for Log Output test</summary>
<p>

<b>Log Output Details:</b> It's considered a best-practice for containers and pods to output logs to STDOUT/STDERR so that commands return useful debug or other information about the application.

For example, running `kubectl get logs` returns useful information for diagnosing or troubleshooting issues. 

<b>Read the [rationale](RATIONALE.md#to-check-if-logs-are-being-sent-to-stdoutstderr-standard-out-standard-error-instead-of-a-log-file-log_output) behind this test.</b>

<b>Remediation Steps:</b> Make sure applications and CNF's are sending log output to STDOUT and or STDERR.
</p>

</details>

```
./cnf-testsuite log_output
``` 
##### :heavy_check_mark: To check if prometheus is installed and configured for the cnf 
<details> <summary>Details for prometheus traffic test</summary>
<p>

<b>Prometheus Traffic Details:</b> It's considered a best-practice for CNFs to actively expose metrics.

<b>Read the [rationale](RATIONALE.md#to-check-if-prometheus-is-installed-and-configured-for-the-cnf-prometheus_traffic) behind this test.</b>

<b>Remediation Steps:</b> Install and configure Prometheus for your CNF.
</p>

</details>

```
./cnf-testsuite prometheus_traffic 
``` 
##### :heavy_check_mark: To check if logs and data are being routed through fluentd
<details> <summary>Details for fluentd routed logging</summary>
<p>

<b>Routed Logs Details:</b> It's considered a best-practice for CNFs to route logs and data through programs like fluentd to analyze and better understand data. This test will check if your CNF is using fluentd.

<b>Read the [rationale](RATIONALE.md#to-check-if-logs-and-data-are-being-routed-through-fluentd-routed_logs) behind this test.</b>

<b>Remediation Steps:</b> Install and configure fluentd to collect data and logs. See more at [fluentd.org](https://bit.ly/fluentd).
</p>

</details>

```
./cnf-testsuite routed_logs
```

##### :heavy_check_mark: To check if OpenMetrics is being used and or compatible.
<details> <summary>Details for OpenMetrics</summary>

<p>

<b>OpenMetics Details:</b> OpenMetrics specifies the de-facto standard for transmitting cloud-native metrics at scale, with support for both text representation and Protocol Buffers and brings it into an Internet Engineering Task Force (IETF) standard. It supports both pull and push-based data collection. Sourced from [OpenMetrics Readme](https://github.com/OpenObservability/OpenMetrics/blob/main/specification/OpenMetrics.md)

<b>Read the [rationale](RATIONALE.md#to-check-if-openmetrics-is-being-used-and-or-compatible-open_metrics) behind this test.</b>

<b>Remediation Steps:</b> Ensure your CNF is OpenMetrics compatible.
</p>

</details>

```
./cnf-testsuite open_metrics
```
##### :heavy_check_mark: To check if tracing is being used with Jaeger.
<details> <summary>Details for tracing with Jaeger</summary>

<p>

<b>Tracing Details:</b> Jaeger uses distributed tracing to follow the path of a request through different microservices. Rather than guessing, we can see a visual representation of the call flows. Sourced from [Red Hat's blog on Jaeger](https://www.redhat.com/en/topics/microservices/what-is-jaeger)

<b>Read the [rationale](RATIONALE.md#to-check-if-tracing-is-being-used-with-jaeger-tracing) behind this test.</b>

<b>Remediation Steps:</b> Ensure your CNF is using tracing.
</p>

</details>

```
./cnf-testsuite tracing
```

#### Security Tests

##### :heavy_check_mark: To run all of the security tests

```
./cnf-testsuite security
```

##### :heavy_check_mark: To check if a CNF is using container socket mounts
<details> <summary>Details for container socket mounts</summary>
<p>

<b>Container Socker Mounts Details:</b> Container daemon socket bind mounts allows access to the container engine on the node. This access can be used for privilege escalation and to manage containers outside of Kubernetes, and hence should not be allowed

<b>Remediation Steps:</b> Make sure to not mount `/var/run/docker.sock`, `/var/run/containerd.sock` or `/var/run/crio.sock` on the containers
</p>

</details>

```
./cnf-testsuite container_sock_mounts
```

##### :heavy_check_mark: To check if any containers are running in [privileged mode](https://github.com/open-policy-agent/gatekeeper)
<details> <summary>Details for privileged mode</summary>
<p>

<b>Privileged mode:</b> 

<b>Remediation:</b> TBD
</p>

</details>

```
./cnf-testsuite privileged
```

##### :heavy_check_mark: To check if any pods in the CNF use sysctls with restricted values
<details>
  <summary>Details for sysctls test</summary>
  <p>
    <b>Details:</b> Sysctls can disable security mechanisms or affect all containers on a host, and should be disallowed except for an allowed "safe" subset. A sysctl is considered safe if it is namespaced in the container or the Pod, and it is isolated from other Pods or processes on the same Node. This test ensures that only those "safe" subsets are specified in a Pod.
  </p>
  <p>
    <b>Remediation Steps:</b> Setting additional sysctls above the allowed type is disallowed. The field spec.securityContext.sysctls must be unset or not use any other names than kernel.shm_rmid_forced, net.ipv4.ip_local_port_range, net.ipv4.ip_unprivileged_port_start, net.ipv4.tcp_syncookies and net.ipv4.ping_group_range.
  </p>
</details>

```
./cnf-testsuite sysctls
```

##### :heavy_check_mark: To check if a CNF is running services with external IPs
<details> <summary>Details for external IPs</summary>
<p>

<b>External IP's Details:</b> Service externalIPs can be used for a MITM attack (CVE-2020-8554). Restrict externalIPs or limit to a known set of addresses. See: https://github.com/kyverno/kyverno/issues/1367

<b>Remediation Steps:</b> Make sure to not define external IPs in your kubernetes service configuration
</p>

</details>

```
./cnf-testsuite external_ips
```


##### :heavy_check_mark: To check if any containers are running as a [root user](https://github.com/cncf/cnf-wg/blob/main/cbpps/0002-no-root-in-containers.md)
<details> <summary>Details for non root user</summary>
<p>

<b>Non root user:</b> 

<b>Read the [rationale](RATIONALE.md#to-check-if-any-containers-are-running-as-a-root-user-checks-the-user-outside-the-container-that-is-running-dockerd-non_root_user) behind this test.</b>

<b>Remediation:</b> TBD
</p>

</details>

```
./cnf-testsuite non_root_user
```

##### :heavy_check_mark: To check if any containers allow for [privilege escalation](https://bit.ly/C0016_privilege_escalation)
<details> <summary>Details for Privilege Escalation</summary>
<p>

<b>Privilege Escalation:</b> Check that the allowPrivilegeEscalation field in securityContext of container is set to false.

<b>Read the [rationale](RATIONALE.md#to-check-if-any-containers-allow-for-privilege-escalation-privilege_escalation) behind this test.</b>

<b>Remediation:</b> If your application does not need it, make sure the allowPrivilegeEscalation field of the securityContext is set to false.

See more at [ARMO-C0016](https://bit.ly/C0016_privilege_escalation)

</p>
</details>

```
./cnf-testsuite privilege_escalation
```

##### :heavy_check_mark: To check if an attacker can use a [symlink](https://bit.ly/C0058_symlink_filesystem) for arbitrary host file system access
<details> <summary>Details for Symlink Filesystem Access</summary>
<p>

<b>CVE-2021-25741 Symlink Host Access:</b> A user may be able to create a container with subPath or subPathExpr volume mounts to access files & directories anywhere on the host filesystem. Following Kubernetes versions are affected: v1.22.0 - v1.22.1, v1.21.0 - v1.21.4, v1.20.0 - v1.20.10, version v1.19.14 and lower. This control checks the vulnerable versions and the actual usage of the subPath feature in all Pods in the cluster.

<b>Read the [rationale](RATIONALE.md#to-check-if-an-attacker-can-use-a-symlink-for-arbitrary-host-file-system-access-cve-2021-25741-symlink_file_system) behind this test.</b>

<b>Remediation:</b> To mitigate this vulnerability without upgrading kubelet, you can disable the VolumeSubpath feature gate on kubelet and kube-apiserver, or remove any existing Pods using subPath or subPathExpr feature.

See more at [ARMO-C0058](https://bit.ly/C0058_symlink_filesystem)

</p>
</details>

```
./cnf-testsuite symlink_file_system
```

##### :heavy_check_mark: To check if there are [application credentials stored in configuration or environment variables](https://bit.ly/C0012_application_credentials)
<details> <summary>Details for Service Application Credentials</summary>
<p>

<b>Application Credentials:</b> Developers store secrets in the Kubernetes configuration files, such as environment variables in the pod configuration. Such behavior is commonly seen in clusters that are monitored by Azure Security Center. Attackers who have access to those configurations, by querying the API server or by accessing those files on the developer’s endpoint, can steal the stored secrets and use them.

Check if the pod has sensitive information in environment variables, by using list of known sensitive key names. Check if there are configmaps with sensitive information.

<b>Read the [rationale](RATIONALE.md#to-check-if-there-are-service-accounts-that-are-automatically-mapped-application_credentials) behind this test.</b>

<b>Remediation:</b> Use Kubernetes secrets or Key Management Systems to store credentials.

See more at [ARMO-C0012](https://bit.ly/C0012_application_credentials)

</p>
</details>

```
./cnf-testsuite application_credentials
```


##### :heavy_check_mark: To check if there is a [host network attached to a pod](https://bit.ly/C0041_hostNetwork)
<details> <summary>Details for hostNetwork</summary>
<p>

<b>hostNetwork:</b> PODs should not have access to the host systems network.

<b>Read the [rationale](RATIONALE.md#to-check-if-there-is-a-host-network-attached-to-a-pod-host_network) behind this test.</b>

<b>Remediation:</b> Only connect PODs to hostNetwork when it is necessary. If not, set the hostNetwork field of the pod spec to false, or completely remove it (false is the default). Whitelist only those PODs that must have access to host network by design.

See more at [ARMO-C0041](https://bit.ly/C0041_hostNetwork)

</p>
</details>

```
./cnf-testsuite host_network
``` 

##### :heavy_check_mark: To check if there are [service accounts that are automatically mapped](https://bit.ly/C0034_service_account_mapping)
<details> <summary>Details for Service Account Mapping</summary>
<p>

<b>Service Account Mapping:</b> The automatic mounting of service account tokens should be disabled.

<b>Remediation:</b> Disable automatic mounting of service account tokens to PODs either at the service account level or at the individual POD level, by specifying the automountServiceAccountToken: false. Note that POD level takes precedence.

See more at [ARMO-C0034](https://bit.ly/C0034_service_account_mapping)

</p>
</details>

```
./cnf-testsuite service_account_mapping
```

##### :heavy_check_mark: To check if there is an [ingress and egress policy defined](https://bit.ly/3bhT10s).
<details> <summary>Details for ingress_egress_blocked test</summary>
<p>

<b>Ingress Egress Blocked: </b> Network policies control traffic flow between Pods, namespaces, and external IP addresses. By default, no network policies are applied to Pods or namespaces, resulting in unrestricted ingress and egress traffic within the Pod network. Pods become isolated through a network policy that applies to the Pod or the Pod’s namespace. Once a Pod is selected in a network policy, it rejects any connections that are not specifically allowed by any applicable policy object.Administrators should use a default policy selecting all Pods to deny all ingress and egress traffic and ensure any unselected Pods are isolated. Additional policies could then relax these restrictions for permissible connections.(For ARMO runtime needs to add exception). See more at [Armo's C-0030 doc on ingress egress blocked details](https://bit.ly/3bhT10s).

<b>Read the [rationale](RATIONALE.md#to-check-if-there-is-an-ingress-and-egress-policy-defined-ingress_egress_blocked) behind this test.</b>

<b>Remediation Steps: </b> By default, you should disable or restrict Ingress and Egress traffic on all pods.

</details>

```
./cnf-testsuite ingress_egress_blocked
```
##### :heavy_check_mark: To check if there are any privileged containers

<details> <summary>Details for Privileged Containers</summary>
<p>

<b>Privileged Containers:</b> A privileged container is a container that has all the capabilities of the host machine, which lifts all the limitations regular containers have. This means that privileged containers can do almost every action that can be performed directly on the host. Attackers who gain access to a privileged container or have permissions to create a new privileged container (by using the compromised pod’s service account, for example), can get access to the host’s resources.

<b>Read the [rationale](RATIONALE.md#to-check-if-there-are-any-privileged-containers-kubscape-version-privileged_containers) behind this test.</b>
    
<b>Remediation:</b> Change the deployment and/or pod definition to unprivileged. The securityContext.privileged should be false.
    
Read more at [ARMO-C0057](https://bit.ly/31iGng3)
    
</p>
</details>

```
./cnf-testsuite privileged_containers
```

##### :heavy_check_mark: To check for insecure capabilities
<details> <summary>Details for Insecure Capabilities</summary>
<p>

<b>Insecure Capabilities:</b> Giving insecure and unnecessary capabilities for a container can increase the impact of a container compromise.

This test checks against a [blacklist of insecure capabilities](https://github.com/FairwindsOps/polaris/blob/master/checks/insecureCapabilities.yaml).

<b>Read the [rationale](RATIONALE.md#to-check-for-insecure-capabilities-insecure_capabilities) behind this test.</b>

<b>Remediation:</b> Remove all insecure capabilities which aren’t necessary for the container.

See more at [ARMO-C0046](https://bit.ly/C0046_Insecure_Capabilities)

</p>
</details>

```
./cnf-testsuite insecure_capabilities
```

##### :heavy_check_mark: To check for dangerous capabilities
<details> <summary>Details for Dangerous Capabilities</summary>
<p>

<b>Dangerous Capabilities:</b> Giving dangerous and unnecessary capabilities for a container can increase the impact of a container compromise.

This test checks against a [blacklist of dangerous capabilities](https://github.com/FairwindsOps/polaris/blob/master/checks/dangerousCapabilities.yaml).

<b>Read the [rationale](RATIONALE.md#to-check-for-dangerous-capabilities-dangerous_capabilities) behind this test.</b>

<b>Remediation:</b> Check and remove all unnecessary capabilities from the POD security context of the containers and use the exception mechanism to remove warnings where these capabilities are necessary.

See more at [ARMO-C0028](https://bit.ly/C0028_Dangerous_Capabilities)

</p>
</details>

```
./cnf-testsuite dangerous_capabilities
```

##### :heavy_check_mark: To check if namespaces have network policies defined
<details> <summary>Details for Network Policies</summary>
<p>

<b>Network Policies:</b> There is a MITRE check that fails if there are no policies defined for a specific namespace (cluster internal networking).

If no network policy is defined, attackers who gain access to a single container may use it to probe the network. Lists namespaces in which no network policies are defined.

<b>Read the [rationale](RATIONALE.md#to-check-if-namespaces-have-network-policies-defined-network_policies) behind this test.</b>

<b>Remediation:</b> Define network policies or use similar network protection mechanisms.
    
Read more at [ARMO-C0011](https://bit.ly/2ZEwb0A)
    
</p>
</details>

```
./cnf-testsuite network_policies
```

##### :heavy_check_mark: To check if containers are running with non-root user with non-root membership
<details> <summary>Details for Non Root Containers</summary>
<p>

<b>Non Root Containers:</b> Container engines allow containers to run applications as a non-root user with non-root group membership. Typically, this non-default setting is configured when the container image is built. . Alternatively, Kubernetes can load containers into a Pod with SecurityContext:runAsUser specifying a non-zero user. While the runAsUser directive effectively forces non-root execution at deployment, NSA and CISA encourage developers to build container applications to execute as a non-root user. Having non-root execution integrated at build time provides better assurance that applications will function correctly without root privileges.

<b>Read the [rationale](RATIONALE.md#to-check-if-containers-are-running-with-non-root-user-with-non-root-membership-non_root_containers) behind this test.</b>

<b>Remediation:</b> If your application does not need root privileges, make sure to define the runAsUser and runAsGroup under the PodSecurityContext to use user ID 1000 or higher, do not turn on allowPrivlegeEscalation bit and runAsNonRoot is true.
    
Read more at [ARMO-C0013](https://bit.ly/2Zzlts3)
    
</p>
</details>

```
./cnf-testsuite non_root_containers
```

##### :heavy_check_mark: To check if containers are running with hostPID or hostIPC privileges
<details> <summary>Details for hostPID and hostIPC Privileges</summary>
<p>

<b>Host PID/IPC Privileges:</b> Containers should be as isolated as possible from the host machine. The hostPID and hostIPC fields in Kubernetes may excessively expose the host for potentially malicious actions.

<b>Read the [rationale](RATIONALE.md#to-check-if-containers-are-running-with-hostpid-or-hostipc-privileges-host_pid_ipc_privileges) behind this test.</b>

<b>Remediation:</b> Apply least privilege principle and disable the hostPID and hostIPC fields unless strictly needed.
    
Read more at [ARMO-C0038](https://bit.ly/3nGvpIQ)
    
</p>
</details>

```
./cnf-testsuite host_pid_ipc_privileges
```

##### :heavy_check_mark: To check if CNF resources use custom SELinux options that allow privilege escalation
<details>
<summary>Details for `selinux_options`</summary>

<p>
SELinux options can be used to escalate privileges and should not be allowed.

<b>Remediation steps:</b>
Ensure the following guidelines are followed for any cluster resource that allow SELinux options.
  <ul>
    <li>
    If the SELinux option `type` is set, it should only be one of the allowed values: `container_t`, `container_init_t`, or `container_kvm_t`.
    </li>
    <li>
    SELinux options `user` or `role` should not be set.
    </li>
  </ul>
  
</p>
</details>

```
./cnf-testsuite selinux_options
```
##### :heavy_check_mark: To check if security services are being used to harden containers
<details> <summary>Details for Linux Hardening</summary>
<p>

<b>Linux Hardening:</b> Check if there is AppArmor, Seccomp, SELinux or Capabilities are defined in the securityContext of container and pod. If none of these fields are defined for both the container and pod, alert.

<b>Read the [rationale](RATIONALE.md#to-check-if-security-services-are-being-used-to-harden-containers-linux_hardening) behind this test.</b>
    
<b>Remediation:</b> In order to reduce the attack surface, it is recommended to harden your application using security services such as SELinux®, AppArmor®, and seccomp. Starting from Kubernetes version 22, SELinux is enabled by default.
    
Read more at [ARMO-C0055](https://bit.ly/2ZKOjpJ)
    
</p>
</details>

```
./cnf-testsuite linux_hardening
```

##### :heavy_check_mark: To check if containers have resource limits defined
<details> <summary>Details for Resource Policies</summary>
<p>

<b>Resource Policies:</b> CPU and memory resources should have a limit set for every container to prevent resource exhaustion.

Check for each container if there is a ‘limits’ field defined. Check for each limitrange/resourcequota if there is a max/hard field defined, respectively.

<b>Read the [rationale](RATIONALE.md#to-check-if-containers-have-resource-limits-defined-resource_policies) behind this test.</b>
    
<b>Remediation:</b> Define LimitRange and ResourceQuota policies to limit resource usage for namespaces or nodes.
    
Read more at [ARMO-C0009](https://bit.ly/3Ezxkps)
    
</p>
</details>

```
./cnf-testsuite resource_policies
```

##### :heavy_check_mark: To check if containers have immutable file systems
<details> <summary>Details for Immutable File Systems</summary>
<p>

<b>Immutable Filesystems:</b> Mutable container filesystem can be abused to gain malicious code and data injection into containers. Use immutable (read-only) filesystem to limit potential attacks.

Checks whether the readOnlyRootFilesystem field in the SecurityContext is set to true.

<b>Read the [rationale](RATIONALE.md#to-check-if-containers-have-immutable-file-systems-immutable_file_systems) behind this test.</b>

<b>Remediation:</b> Set the filesystem of the container to read-only when possible. If the containers application needs to write into the filesystem, it is possible to mount secondary filesystems for specific directories where application require write access.
    
Read more at [ARMO-C0017](https://bit.ly/3pSMtxK)
    
</p>
</details>

```
./cnf-testsuite immutable_file_systems
```

##### :heavy_check_mark: To check if containers have hostPath mounts
<details> <summary>Details for Hostpath Mounts</summary>
<p>

<b>Writable Hostpath Mounts:</b> Mounting host directory to the container can be abused to get access to sensitive data and gain persistence on the host machine.

hostPath volume mounts a directory or a file from the host to the container. Attackers who have permissions to create a new container in the cluster may create one with a writable hostPath volume and gain persistence on the underlying host. For example, the latter can be achieved by creating a cron job on the host.

<b>Read the [rationale](RATIONALE.md#to-check-if-containers-have-hostpath-mounts-check-is-this-a-duplicate-of-state-test---cnf-testsuite-volume_hostpath_not_found-hostpath_mounts) behind this test.</b>
    
<b>Remediation:</b> Refrain from using host path mount.
    
Read more at [ARMO-C0045](https://bit.ly/3EvltIL)
    
</p>
</details>

```
./cnf-testsuite hostpath_mounts
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

#### Configuration Tests

##### :heavy_check_mark: To run all of the configuration and lifecycle tests

```
./cnf-testsuite configuration_lifecycle
```

##### :heavy_check_mark: To check if resources of the CNF are not in the default namespace
<details>
<summary>Details for default namespace</summary>
<p>

<b>Kubernetes Namespaces:</b> Default namespces provide a way to segment and isolate cluster resources across multiple applications and users. As a best practice, workloads should be isolated with Namespaces.

<b>Remediation steps:</b> Namespaces should be required and the default (empty) Namespace should not be used. This policy validates that Pods specify a Namespace name other than `default`.

</p>
</details>

```
./cnf-testsuite default_namespace
```


##### :heavy_check_mark: To check if Pods in the CNF use container images with the latest tag
<details>
<summary>Details for `latest_tag`</summary>
<p>

<b>Latest tag:</b> The `:latest` tag is mutable and can lead to unexpected errors if the image changes. Even when a tag is not specified, the `:latest` tag is used by default.

<b>Read the [rationale](RATIONALE.md#to-test-if-there-are-versioned-tags-on-all-images-using-opa-gatekeeper) behind this test.</b>

<b>Remediation steps:</b> When specifying container images, always specify a tag and ensure to use an immutable tag that maps to a specific version of an application Pod. Avoid using the `latest` tag, as it is not guaranteed to be always point to the same version of the image.

</p>
</details>

```
./cnf-testsuite latest_tag
```
=======

```
./cnf-testsuite default_namespace
```

<details>
<summary>Details for `default_namespace`</summary>

<p>
Kubernetes Namespaces provide a way to segment and isolate cluster resources across multiple applications and users. As a best practice, workloads should be isolated with Namespaces.
</p>

<p>
<b>Remediation steps:</b> Namespaces should be required and the default (empty) Namespace should not be used. This policy validates that Pods specify a Namespace name other than `default`.
</p>

</details>

##### :heavy_check_mark: To check if Pods in the CNF use container images with the latest tag

```
./cnf-testsuite latest_tag
```

<details>
<summary>Details for `latest_tag`</summary>

<p>
The `:latest` tag is mutable and can lead to unexpected errors if the image changes. Even when a tag is not specified, the `:latest` tag is used by default.
</p>

<p>
<b>Remediation steps:</b> When specifying container images, always specify a tag and ensure to use an immutable tag that maps to a specific version of an application Pod. Avoid using the `latest` tag, as it is not guaranteed to be always point to the same version of the image.
</p>

</details>

##### :heavy_check_mark: To check if pods are using the `app.kubernetes.io/name` label
<details> <summary>Details for labels test</summary>
<p>

<b>Labels Details:</b> Defining and using labels help to identify semantic attributes of your application or Deployment. A common set of labels allows tools to work collaboratively, describing objects in a common manner that all tools can understand. The recommended labels describe applications in a way that can be queried

<b>Remediation Steps:</b> Make sure to define `app.kubernetes.io/name` label under metadata
</p>

</details>

```
./cnf-testsuite require_labels
```


##### :heavy_check_mark: To test if there are versioned tags on all images using OPA Gatekeeper
<details> <summary>Details for versioned tag</summary>
<p>

<b>Versioned tag:</b> 

<b>Remediation:</b> TBD
</p>

</details>

```
./cnf-testsuite versioned_tag
```

##### :heavy_check_mark: To test if there are any (non-declarative) hardcoded IP addresses or subnet masks
<details> <summary>Details for IP Addresses</summary>
<p>

<b>IP Addresses:</b> 

<b>Remediation:</b> TBD
</p>

</details>

```
./cnf-testsuite ip_addresses
```

##### :heavy_check_mark: To test if there are node ports used in the service configuration
<details> <summary>Details for nodeports not used</summary>
<p>

<b>Nodeports in use:</b> 

<b>Read the [rationale](RATIONALE.md#to-test-if-there-are-node-ports-used-in-the-service-configuration) behind this test.</b>

<b>Remediation:</b> TBD
</p>

</details>

```
./cnf-testsuite nodeport_not_used
```

##### :heavy_check_mark: To test if there are host ports used in the service configuration
<details> <summary>Details for hostport not used</summary>
<p>

<b>Hostport not used:</b> 

<b>Read the [rationale](RATIONALE.md#to-test-if-there-are-host-ports-used-in-the-service-configuration) behind this test.</b>

<b>Remediation:</b> TBD
</p>

</details>

```
./cnf-testsuite hostport_not_used
```

##### :heavy_check_mark: To test if there are any (non-declarative) hardcoded IP addresses or subnet masks in the K8s runtime configuration
<details> <summary>Details for hardcoded ip address in k8s runtime config</summary>
<p>

<b>hardcoded ip addresses in k8s runtime conf:</b> 

<b>Read the [rationale](RATIONALE.md#to-test-if-there-are-any-non-declarative-hardcoded-ip-addresses-or-subnet-masks-in-the-k8s-runtime-configuration) behind this test.</b>

<b>Remediation:</b> TBD
</p>

</details>

```
./cnf-testsuite hardcoded_ip_addresses_in_k8s_runtime_configuration
```

##### :heavy_check_mark: To check if a CNF uses K8s secrets
<details> <summary>Additional Information</summary>
<p>

<b>Rules for the test:</b> The whole test passes if _any_ workload resource in the cnf uses a (non-exempt) secret. If no workload resources use a (non-exempt) secret, the test is skipped.

<b>Read the [rationale](RATIONALE.md#to-check-if-a-cnf-uses-k8s-secrets-secrets_used) behind this test.</b>
    
</p>
</details>

```
./cnf-testsuite secrets_used
```

##### :heavy_check_mark: To check if a CNF version uses [immutable configmaps](https://kubernetes.io/docs/concepts/configuration/configmap/#configmap-immutable)
<details> <summary>Details for immutable configmap</summary>
<p>

<b>Immutable configmap:</b> 

<b>Read the [rationale](RATIONALE.md#to-check-if-a-cnf-version-uses-immutable-configmaps-immutable_configmap) behind this test.</b>

<b>Remediation:</b> TBD
</p>

</details>

```
./cnf-testsuite immutable_configmap
```

#### :heavy_check_mark: Test if the CNF crashes when pod dns error occurs
<details> <summary>Details for pod DNS error</summary>
<p>

<b>Pod DNS Error:</b> 

<b>Remediation:</b> TBD
</p>

</details>

```
./cnf-testsuite pod_dns_error
```

### Platform Tests

##### :heavy_check_mark: Run all platform tests

```
./cnf-testsuite platform
```

##### :heavy_check_mark: Run the K8s conformance tests

```
./cnf-testsuite k8s_conformance
```

##### :heavy_check_mark: To test if Cluster API is enabled on the platform and manages a node

```
./cnf-testsuite clusterapi_enabled
```

##### :heavy_check_mark: Run All platform harware and scheduling tests

```
./cnf-testsuite  platform:hardware_and_scheduling
```

##### :heavy_check_mark: Run runtime compliance test

```
./cnf-testsuite platform:oci_compliant
```

##### :bulb: (PoC) Run All platform observability tests

```
./cnf-testsuite platform:observability poc
```

##### :bulb: (PoC) Run All platform resilience tests

```
./cnf-testsuite platform:resilience poc
```

##### :x: :bulb: (PoC) Run node failure test. WARNING this is a destructive test and will reboot your _host_ node!

##### Do not run this unless you have completely separate cluster, e.g. development or test cluster.

```
./cnf-testsuite platform:node_failure poc destructive
```

##### :heavy_check_mark: Run All platform security tests

```
./cnf-testsuite platform:security 
```
##### :heavy_check_mark: To check if [cluster admin is bound to a pod](https://bit.ly/C0035_cluster_admin)
<details> <summary>Details for Cluster Admin Binding</summary>

<p><b>Cluster Admin Binding:</b> Role-based access control (RBAC) is a key security feature in Kubernetes. RBAC can restrict the allowed actions of the various identities in the cluster. Cluster-admin is a built-in high privileged role in Kubernetes. Attackers who have permissions to create bindings and cluster-bindings in the cluster can create a binding to the cluster-admin ClusterRole or to other high privileges roles.

Check which subjects have cluster-admin RBAC permissions – either by being bound to the cluster-admin clusterrole, or by having equivalent high privileges.

<b>Remediation:</b> You should apply least privilege principle. Make sure cluster admin permissions are granted only when it is absolutely necessary. Don't use subjects with high privileged permissions for daily operations.

See more at [ARMO-C0035](https://bit.ly/C0035_cluster_admin)

</p>
</details>

```
./cnf-testsuite platform:cluster_admin
```

##### :heavy_check_mark: To check if [the control plane is hardened](https://bit.ly/C0005_Control_Plane)
<details> <summary>Details for Control Plane Hardening</summary>

<p><b>Control Plane Hardening:</b> The control plane is the core of Kubernetes and gives users the ability to view containers, schedule new Pods, read Secrets, and execute commands in the cluster. Therefore, it should be protected. It is recommended to avoid control plane exposure to the Internet or to an untrusted network. The API server runs on ports 6443 and 8080. We recommend to block them in the firewall. Note that port 8080, when accessed through the local machine, does not require TLS encryption, and the requests bypass authentication and authorization modules.

Checks if the insecure-port flag is set (in case of cloud vendor hosted Kubernetes service this verification will not be effective).

<b>Remediation:</b> Set the insecure-port flag of the API server to zero.

See more at [ARMO-C0005](https://bit.ly/C0005_Control_Plane)

</p>
</details>

```
./cnf-testsuite platform:control_plane_hardening
```

##### :heavy_check_mark: To check if dashboard is exposed

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

##### :heavy_check_mark: To check if containers are using any tiller images
<details> <summary>Details for tiller images</summary>
<p>

<b>Tiller Images Details:</b> Tiller, found in Helm v2, has known security challenges. It requires administrative privileges and acts as a shared resource accessible to any authenticated user. Tiller can lead to privilege escalation as restricted users can impact other users. It is recommend to use Helm v3+ which does not contain Tiller for these reasons

<b>Remediation Steps:</b> Make sure not to pull any images with name tiller in them
</p>

</details>

```
./cnf-testsuite platform:helm_tiller
```

