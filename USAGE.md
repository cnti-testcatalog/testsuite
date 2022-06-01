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
# Compatibility, Installability, and Upgradability Tests

##### To run all of the compatibility tests

```
./cnf-testsuite compatibility
```

## [Increase decrease capacity:](https://github.com/cncf/cnf-testsuite/blob/refactor_usage_doc%231371/docs/LIST_OF_TESTS.md#increase-decrease-capacity)
##### To run both increase and decrease tests, you can use the alias command that calls them both:
```
./cnf-testsuite increase_decrease_capacity
```
### [Increase capacity](https://github.com/cncf/cnf-testsuite/blob/refactor_usage_doc%231371/docs/LIST_OF_TESTS.md#increase-capacity)
##### Or, they can be called individually using the following commands:
```
./cnf-testsuite increase_capacity
```
### [Decrease capacity](https://github.com/cncf/cnf-testsuite/blob/refactor_usage_doc%231371/docs/LIST_OF_TESTS.md#decrease-capacity)

```
./cnf-testsuite decrease_capacity
```

<b>Remediation for failing this test:</b>

Check out the kubectl docs for how to [manually scale your cnf.](https://kubernetes.io/docs/reference/kubectl/cheatsheet/#scaling-resources)

Also here is some info about [things that could cause failures.](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#failed-deployment)

</b>



## [Helm chart published](docs/LIST_OF_TESTS.md#helm-chart-published)

##### To run the Helm chart published test, you can use the following command:
```
./cnf-testsuite helm_chart_published
```

<b>Remediation for failing this test:</b>

Make sure your CNF helm charts are published in a Helm Repository.

</b>



## [Helm chart is valid](docs/LIST_OF_TESTS.md#helm-chart-valid)

##### To run the Helm chart vaild test, you can use the following command:
```
./cnf-testsuite helm_chart_valid
```

<b>Remediation for failing this test:</b> 

Make sure your helm charts pass lint tests.

</b>



## [Helm deploy](docs/LIST_OF_TESTS.md#helm-deploy)

##### To run the Helm deploy test, you can use the following command:
```
./cnf-testsuite helm_deploy
```

<b>Remediation for failing this test:</b> 

Make sure your helm charts are valid and can be deployed to clusters.

</b>



## [Rollback](docs/LIST_OF_TESTS.md#rollback)

##### To run the Rollback test, you can use the following command:
```
./cnf-testsuite rollback
```
<b>Remediation for failing this test:</b> 

Ensure that you can upgrade your CNF using the [Kubectl Set Image](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#-em-image-em-) command, then rollback the upgrade using the [Kubectl Rollout Undo](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#rollout) command.

</b>


### [Rolling update](docs/LIST_OF_TESTS.md#rolling-update)

##### To run the Rolling update test, you can use the following command:
```
./cnf-testsuite rolling_update
```

<b>Remediation for failing this test:</b> 

Ensure that you can successfuly perform a rolling upgrade of your CNF using the [Kubectl Set Image](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#-em-image-em-) command.

</b>



### [Rolling version change](docs/LIST_OF_TESTS.md#rolling-version-change)

##### To run the Rolling version change test, you can use the following command:
```
./cnf-testsuite rolling_version_change
```

<b>Remediation for failing this test:</b> 

Ensure that you can successfuly rollback the software version of your CNF by using the [Kubectl Set Image](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#-em-image-em-) command.

</b>


### [Rolling downgrade](docs/LIST_OF_TESTS.md#rolling-downgrade)

##### To run the Rolling downgrade test, you can use the following command:
```
./cnf-testsuite rolling_downgrade
```

<b>Remediation for failing this test:</b> 

Ensure that you can successfuly change the software version of your CNF back to an older version by using the [Kubectl Set Image](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#-em-image-em-) command.

</b>


## [CNF compatible](docs/LIST_OF_TESTS.md#cni-compatible)

##### To run the CNI compatible test, you can use the following command:
```
./cnf-testsuite cni_compatible
```

<b>Remediation for failing this test:</b> 

Ensure that your CNF is compatible with Calico, Cilium and other available CNIs.

</b>



## [Kubernetes Alpha APIs](docs/LIST_OF_TESTS.md#kubernetes-alpha-apis---proof-of-concept)

##### To run the Kubernetes Alpha APIs test, you can use the following command:
```
./cnf-testsuite alpha_k8s_apis
```

<b>Remediation for failing this test:</b> 

Make sure your CNFs are not utilizing any Kubernetes alpha APIs. You can learn more about Kubernetes API versioning [here](https://bit.ly/k8s_api).

</b>



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


# Microservice Tests

##### To run all of the microservice tests

```
./cnf-testsuite microservice
```

## [Reasonable Image Size](docs/LIST_OF_TESTS.md#reasonable-image-size)

##### To run the Reasonable image size, you can use the following command:
```
./cnf-testsuite reasonable_image_size
```

<b>Remediation for failing this test:</b> 

Enure your CNFs image size is under 5GB.

</b>



## [Reasonable startup time](docs/LIST_OF_TESTS.md#reasonable-startup-time)

##### To run the Reasonable startup time test, you can use the following command:

```
./cnf-testsuite reasonable_startup_time
```

<b>Remediation for failing this test:</b> 

Ensure that your CNF gets into a running state within 30 seconds.

</b>


## [Single process type in one container](docs/LIST_OF_TESTS.md#single-process-type-in-one-container)

##### To run the Single process type test, you can use the following command:

```
./cnf-testsuite single_process_type
```

<b>Remediation for failing this test:</b> 

Ensure that there is only one process type within a container. This does not count against child processes, e.g. nginx or httpd could be a parent process with 10 child processes and pass this test, but if both nginx and httpd were running, this test would fail.

</b>




## [Service discovery](docs/LIST_OF_TESTS.md#service-discovery)

##### To run the Service discovery test, you can use the following command:

```
./cnf-testsuite service_discovery
```

<b>Remediation for failing this test:</b> 
  
Make sure the CNF exposes any of its containers as a Kubernetes Service. You can learn more about Kubernetes Service [here](https://kubernetes.io/docs/concepts/services-networking/service/).
  
</b>



## [Shared database](docs/LIST_OF_TESTS.md#shared-database)

##### To run the Shared database test, you can use the following command:


```
./cnf-testsuite shared_database 
```

<b>Remediation for failing this test:</b> 

Make sure that your CNFs containers are not shareing the same [database](https://martinfowler.com/bliki/IntegrationDatabase.html).
</b>



# State Tests

##### To run all of the state tests:

```
./cnf-testsuite state
```

## [Node drain](docs/LIST_OF_TESTS.md#node-drain)

##### To run the Node drain test, you can use the following command:

```
./cnf-testsuite node_drain
```

<b>Remediation for failing this test</b> 
Ensure that your CNF can be successfully rescheduled when a node fails or is [drained](https://kubernetes.io/docs/tasks/administer-cluster/safely-drain-node/)
</b>




## [Volume hostpath not found](docs/LIST_OF_TESTS.md#volume-hostpath-not-found)

##### To run the Volume hostpath not found test, you can use the following command:

```
./cnf-testsuite volume_hostpath_not_found
```

<b>Remediation for failing this test:</b> 
Ensure that none of the containers in your CNFs are using ["hostPath"] to mount volumes.
</b>



## [No local volume configuration](docs/LIST_OF_TESTS.md#no-local-volume-configuration)

##### To run the No local volume configuration test, you can use the following command:

```
./cnf-testsuite no_local_volume_configuration
```

<b>Remediation for failing this test:</b>
Ensure that your CNF isn't using any persistent volumes that use a ["local"] mount point.
</b>



## [Elastic volumes](docs/LIST_OF_TESTS.md#no-local-volume-configuration)

##### To run the Elastic volume test, you can use the following command:

```
./cnf-testsuite elastic_volume
```

<b>Remediation for failing this test:</b> 
Setup and use elastic persistent volumes instead of local storage.
</b>



## [Database persistence](docs/LIST_OF_TESTS.md#database-persistence)

##### To run the Database persistence test, you can use the following command:

```
./cnf-testsuite database_persistence 
```

<b>Remediation for failing this test:</b> 
Select a database configuration that uses statefulsets and elastic storage volumes.
</b>


# Reliability, Resilience and Availability

##### To run all of the resilience tests
```
./cnf-testsuite resilience
```

## [CNF network latency](docs/LIST_OF_TESTS.md#cnf-under-network-latency)

##### To run the CNF network latency test, you can use the following command:

```
./cnf-testsuite pod_network_latency
```

<b>Remediation for failing this test:</b> 
Ensure that your CNF doesn't stall or get into a corrupted state when network degradation occurs.
A mitigation stagagy(in this case keep the timeout i.e., access latency low) could be via some middleware that can switch traffic based on some SLOs parameters.
</b>

## [CNF disk fill](docs/LIST_OF_TESTS.md#cnf-under-network-latency)

##### To run the CNF disk fill test, you can use the following command:

```
./cnf-testsuite disk_fill
```

<b>Remediation for failing this test:</b> 
Ensure that your CNF is resilient and doesn't stall when heavy IO causes a degradation in storage resource availability. 
</b>


## [Pod delete](docs/LIST_OF_TESTS.md#pod-delete)

##### To run the CNF Pod delete test, you can use the following command:
```
./cnf-testsuite pod_delete
```

<b>Remediation for failing this test:</b> 
Ensure that your CNF is resilient and doesn't fail on a forced/graceful pod failure on specific or random replicas of an application. 
</b>


## [Memory hog](docs/LIST_OF_TESTS.md#memory-hog)

##### To run the CNF Pod delete test, you can use the following command:
```
./cnf-testsuite pod_memory_hog
```

<b>Remediation for failing this test:</b> 
Ensure that your CNF is resilient to heavy memory usage and can maintain some level of avaliabliy. 
</b>


## [IO Stress](docs/LIST_OF_TESTS.md#io-stress)

##### To run the IO Stress test, you can use the following command:
```
./cnf-testsuite pod_io_stress
```

<b>Remediation for failing this test:</b> 
Ensure that your CNF is resilient to continuous and heavy disk IO load and can maintain some level of avaliabliy
</b>

## [Network corruption](docs/LIST_OF_TESTS.md#network-corruption)

##### To run the Network corruption test, you can use the following command:
```
./cnf-testsuite pod_network_corruption
```

<b>Remediation for failing this test:</b> 
Ensure that your CNF is resilient to a lossy/flaky network and can maintain a level of avaliabliy.
</b>



## [Network duplication](docs/LIST_OF_TESTS.md#network-duplication)

##### To run the Network duplication test, you can use the following command:
```
./cnf-testsuite pod_network_duplication
```

<b>Remediation for failing this test:</b> 
Ensure that your CNF is resilient to erroneously duplicated packets and can maintain a level of avaliabliy.
</b>


## [Helm chart liveness entry](docs/LIST_OF_TESTS.md#helm-chart-liveness-entry)

##### To run the Helm chart liveness entry test, you can use the following command:
  
```
./cnf-testsuite liveness
```

<b>Remediation for failing this test:</b> 
Ensure that your CNF has a [Liveness Probe](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/) configured.
</b>



## [Helm chart readiness entry](docs/LIST_OF_TESTS.md#helm-chart-readiness-entry)

##### To run the Helm chart readiness entry test, you can use the following command:

```
./cnf-testsuite readiness
```
<b>Remediation for failing this test:</b> 
Ensure that your CNF has a [Readiness Probe](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/) configured.
</b>


# Observability and Diagnostic Tests

##### To run all observability tests, you can use the following command:

```
./cnf-testsuite observability
```

## [Use stdout/stderr for logs](docs/LIST_OF_TESTS.md#use-stdoutstderr-for-logs)

##### To run the stdout/stderr logging test, you can use the following command:

```
./cnf-testsuite log_output
``` 

<b>Remediation for failing this test:</b> 
Make sure applications and CNF's are sending log output to STDOUT and or STDERR.
</b>


## [Prometheus installed](docs/LIST_OF_TESTS.md#use-stdoutstderr-for-logs)

##### To run the Prometheus installed test, you can use the following command:
```
./cnf-testsuite prometheus_traffic 
``` 

<b>Remediation for failing this test:</b> 
Install and configure Prometheus for your CNF.
</b>



## [Fluentd logs](docs/LIST_OF_TESTS.md#fluentd-logs)

##### To run the Fluentd logs test, you can use the following command:
```
./cnf-testsuite routed_logs
```

<b>Remediation for failing this test:</b> 
Install and configure fluentd to collect data and logs. See more at [fluentd.org](https://bit.ly/fluentd).
</b>


## [OpenMetrics compatible](docs/LIST_OF_TESTS.md#openmetrics-compatible)

##### To run the OpenMetrics compatible test, you can use the following command:
```
./cnf-testsuite open_metrics
```

<b>Remediation for failing this test:</b> 
Ensure that your CNF is publishing OpenMetrics compatible metrics.
</b>



## [Jaeger tracing](docs/LIST_OF_TESTS.md#jaeger-tracing)

##### To run the Jaeger tracing test, you can use the following command:
```
./cnf-testsuite tracing
```

<b>Remediation for failing this test:</b> 
Ensure that your CNF is both using & publishing traces to Jaeger.
</b>



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

<b>hostport_not_used: The hostport not used test will look through all containers defined in the installed cnf to see if the hostPort configuration field is in use. If the field is found it will mark the cnf as failed for this test. </b> 

<b>Read the [rationale](RATIONALE.md#to-test-if-there-are-host-ports-used-in-the-service-configuration) behind this test.</b>

<b>Remediation:</b> Review all Helm Charts & Kubernetes Manifest files for the CNF and remove all occurrences of the hostPort field in you configuration. Alternatively, configure a service or use another mechanism for exposing your contianer.
</p>

</details>

```
./cnf-testsuite hostport_not_used
```

##### :heavy_check_mark: To test if there are any (non-declarative) hardcoded IP addresses or subnet masks in the K8s runtime configuration

<details> <summary>Details for hardcoded ip address in k8s runtime config</summary>
<p>
  
<b>hardcoded_ip_addresses_in_k8s_runtime_configuration:</b> The hardcoded ip address test will scan all the Kubernetes resources of the installed cnf to ensure that no static, hardcoded ip addresses are being used in the configuration.

<b>Read the [rationale](RATIONALE.md#to-test-if-there-are-any-non-declarative-hardcoded-ip-addresses-or-subnet-masks-in-the-k8s-runtime-configuration) behind this test.</b>

<b>Remediation: Review all Helm Charts & Kubernetes Manifest files of the CNF and look for any hardcoded usage of ip addresses. If any are found, you will need to use an operator or some other method to abstract the IP management out of your configuration in order to pass this test. </b>
  
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

