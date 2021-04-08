# CNF Conformance Test CLI Usage Documentation 

### Table of Contents
* [Overview](https://github.com/cncf/cnf-conformance/blob/main/USAGE.md#overview)
* [Syntax and Usage](https://github.com/cncf/cnf-conformance/blob/main/USAGE.md#syntax-for-running-any-of-the-tests)
* [Common Examples](https://github.com/cncf/cnf-conformance/blob/main/USAGE.md#common-example-commands)
* [Logging Options](https://github.com/cncf/cnf-conformance/blob/main/USAGE.md#logging-options)
* [Compatibility Tests](https://github.com/cncf/cnf-conformance/blob/main/USAGE.md#compatibility-tests)
* [Statelessness Tests](https://github.com/cncf/cnf-conformance/blob/main/USAGE.md#statelessness-tests)
* [Security Tests](https://github.com/cncf/cnf-conformance/blob/main/USAGE.md#security-tests)
* [Microservice Tests](https://github.com/cncf/cnf-conformance/blob/main/USAGE.md#microservice-tests)
* [Scalability Tests](https://github.com/cncf/cnf-conformance/blob/main/USAGE.md#scalability-tests)
* [Configuration and Lifecycle Tests](https://github.com/cncf/cnf-conformance/blob/main/USAGE.md#configuration-and-lifecycle-tests)
* [Observability Tests](https://github.com/cncf/cnf-conformance/blob/main/USAGE.md#observability-tests)
* [Installable and Upgradeable Tests](https://github.com/cncf/cnf-conformance/blob/main/USAGE.md#installable-and-upgradeable-tests)
* [Hardware Resources and Scheduling Tests](https://github.com/cncf/cnf-conformance/blob/main/USAGE.md#hardware-resources-and-scheduling-tests)
* [Resilience Tests](https://github.com/cncf/cnf-conformance/blob/main/USAGE.md#resilience-tests)
* [Platform Tests](https://github.com/cncf/cnf-conformance/blob/main/USAGE.md#platform-tests)

### Overview
The CNF Conformance Test suite can be run in production mode (using an executable) or in developer mode (using [crystal lang directly](https://github.com/cncf/cnf-conformance/blob/main/INSTALL.md#source-install)).  See the [pseudo code documentation](https://github.com/cncf/cnf-conformance/blob/main/PSEUDO-CODE.md) for examples of how the internals of WIP tests might work.

### Syntax for running any of the tests
```
# Production mode
./cnf-conformance <testname>

# Developer mode
crystal src/cnf-conformance.cr <testname>
```
:star: *Note: All usage commands in this document will use the production (binary executable) syntax unless otherwise stated.

* :heavy_check_mark: indicates implemented into stable release
* :bulb: indicates Proof of Concept
* :memo: indicates To Do
* :x: indicates WARNINGS*

### Results Output

* :heavy_check_mark: PASSED indicates it meets best practice, positive points given.
* :heavy_multiplication_x: SKIPPED indicates the test was skipped (output should provide a reason), no points given.
* :x: FAILED indicates the test failed, negative points given.

---
### Common Example Commands

#### Building the executable
This is the command to build the binary executable if in developer mode or using the source install method ([requires crystal](https://github.com/cncf/cnf-conformance/blob/main/INSTALL.md#source-install)):
```
crystal build src/cnf-conformance.cr
```

#### Validating a cnf-conformance.yml file:
```
./cnf-conformance validate_config cnf-config=[PATH_TO]/cnf-conformance.yml
```

#### Running all of the CNF Conformance tests (platform and workload):
``` 
./cnf-conformance all cnf-config=<path_to_your_config_file>/cnf-conformance.yml
```

#### Running all of the CNF Conformance tests (including proofs of concepts)
``` 
./cnf-conformance all poc cnf-config=<path_to_your_config_file>/cnf-conformance.yml
```
#### Running all of the workload CNF Conformance tests
``` 
crystal src/cnf-conformance.cr workload
cnf-config=<path_to_your_config_file>/cnf-conformance.yml
```

#### Running all of the platform or workload CNF Conformance tests independently:

##### Run platform only tests:
``` 
./cnf-conformance platform
```
##### Run workload only tests:
```
./cnf-conformance workload 
```

#### Get available options and to see all available tests from command line:
```
./cnf-conformance help
```

#### Clean up the CNF Conformance test suite, the K8s cluster, and upstream projects:
```
./cnf-conformance cleanup
```
---
### Logging Options

#### Update the loglevel from command line:
```
# cmd line
./cnf-conformance -l debug test
```
#### If in developer mode, make sure to use - - if running from source:
```
crystal src/cnf-conformance.cr -- -l debug test 
```

#### You can also use env var for logging:
```
LOGLEVEL=DEBUG ./cnf-conformance test
```

:star: Note: When setting log level, the following is the order of precedence:

1. CLI or Command line flag
2. Environment variable
3. CNF-Conformance [Config file](https://github.com/cncf/cnf-conformance/blob/main/config.yml)

##### Verbose Option
Also setting the verbose option for many tasks will add extra output to help with debugging

```
./cnf-conformance test_name verbose
```

#### Running The Linter in Developer Mode

See https://github.com/crystal-ameba/ameba for more details. Follow the [INSTALL](https://github.com/cncf/cnf-conformance/blob/main/INSTALL.md) guide starting at the [Source Install](https://github.com/cncf/cnf-conformance/blob/main/INSTALL.md#source-install) for more details running cnf-conformance in developer mode.

```
shards install # only for first install
crystal bin/ameba.cr
```
---
### Compatibility Tests

#### :heavy_check_mark: To run all of the compatibility tests
```
./cnf-conformance compatibility
```

<details> <summary>Details for Compatibility Tests To Do's</summary>
<p>

#### :memo: (To Do) To check of the CNF's CNI plugin accepts valid calls from the [CNI specification](https://github.com/containernetworking/cni/blob/master/SPEC.md)
```
crystal src/cnf-conformance.cr cni_spec
```
#### :memo: (To Do) To check for the use of alpha K8s API endpoints
```
crystal src/cnf-conformance.cr api_snoop_alpha
```
#### :memo: (To Do) To check for the use of beta K8s API endpoints
```
crystal src/cnf-conformance.cr api_snoop_beta
```
#### :memo: (To Do) To check for the use of generally available (GA) K8s API endpoints
```
crystal src/cnf-conformance.cr api_snoop_general_apis
```
</p>
</details>

---
### Statelessness Tests
#### :heavy_check_mark: To run all of the statelessness tests
```
./cnf-conformance stateless
```

#### :heavy_check_mark:  To test if the CNF uses a volume host path
```
./cnf-conformance volume_hostpath_not_found 
```

#### :heavy_check_mark:  To test if the CNF uses local storage
```
./cnf-conformance no_local_volume_configuration 
```
<details> <summary>Details for Statelessness Tests To Do's</summary>
<p>

#### :memo: (To Do) To test if the CNF responds properly [when being restarted](//https://github.com/litmuschaos/litmus)
```
crystal src/cnf-conformance.cr reset_cnf
```
#### :memo: (To Do) To test if, when parent processes are restarted, the [child processes](https://github.com/falcosecurity/falco) are [reaped](https://github.com/draios/sysdig-inspect)
```
crystal src/cnf-conformance.cr check_reaped
```

</p>
</details>

---
### Security Tests
#### :heavy_check_mark: To run all of the security tests
```
./cnf-conformance security
```

#### :heavy_check_mark: To check if any containers are running in [privileged mode](https://github.com/open-policy-agent/gatekeeper)
```
./cnf-conformance privileged
```

<details> <summary>Details for Security Tests To Do's</summary>
<p>

#### :memo: (To Do) To check if there are any [shells running in the container](https://github.com/open-policy-agent/gatekeeper)
```
crystal src/cnf-conformance.cr shells
```
#### :memo: (To Do) To check if there are any [protected directories](https://github.com/open-policy-agent/gatekeeper) or files that are accessed from within the container
```
crystal src/cnf-conformance.cr protected_access
```

</p>
</details>

---
### Microservice Tests
#### :heavy_check_mark: To run all of the microservice tests
```
./cnf-conformance microservice
```

#### :heavy_check_mark: To check if the CNF has a reasonable image size
```
./cnf-conformance reasonable_image_size
```
#### :heavy_check_mark: To check if the CNF have a reasonable startup time
```
./cnf-conformance reasonable_startup_time destructive
```

---
### Scalability Tests
#### :heavy_check_mark: To run all of the scalability tests
```
./cnf-conformance scalability
```

#### :heavy_check_mark: To test the [increasing and decreasing of capacity](https://kubernetes.io/docs/reference/kubectl/cheatsheet/#scaling-resources)

<details> <summary>Optional: To install the sample coredns cnf: to run test </summary>
<p>

```
./cnf-conformance sample_coredns_setup helm_chart=<helm chart name>
```
Or optionally modify the your cnf's cnf-conformance.yml file to include the helm_chart name, e.g. 
```
helm_chart: stable/coredns
```
To run the capacity test:
```
./cnf-conformance increase_decrease_capacity deployment_name=coredns-coredns
```
Or optionally modify the your cnf's cnf-conformance.yml file to include the deployment name, e.g. 
```
deployment_name: coredns/coredns 
```
</p>
</details>


**Remediation for failing this test:**

Check out the kubectl docs for how to [manually scale your cnf.](https://kubernetes.io/docs/reference/kubectl/cheatsheet/#scaling-resources)

Also here is some info about [things that could cause failures.](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#failed-deployment)


#### :heavy_check_mark: To test if Cluster API is enabled on the platform and manages a node
```
./cnf-conformance clusterapi_enabled
```

<details> <summary>Details for Scalability Tests To Do's</summary>
<p>

#### :memo: (To Do) To test small scale autoscaling
```
crystal src/cnf-conformance.cr small_autoscaling
```
#### :memo: (To Do) To test [large scale autoscaling](https://github.com/cncf/cnf-testbed)
```
crystal src/cnf-conformance.cr large_autoscaling
```
#### :memo: (To Do) To test if the CNF responds to [network](https://github.com/alexei-led/pumba) [chaos](https://github.com/worstcase/blockade)
```
crystal src/cnf-conformance.cr network_chaos
```

#### :memo: (To Do) To test if the CNF control layer uses [external retry logic](https://github.com/envoyproxy/envoy)
```
crystal src/cnf-conformance.cr external_retry
```
</p>
</details>

---
### Configuration and Lifecycle Tests
#### :heavy_check_mark: To run all of the configuration and lifecycle tests
```
./cnf-conformance configuration_lifecycle
```
#### :heavy_check_mark: To test if there is a liveness entry in the Helm chart
```
./cnf-conformance liveness
```
##### :heavy_check_mark: To test if there is a readiness entry in the Helm chart
```
./cnf-conformance readiness
```
#### :heavy_check_mark: To test if there are any (non-declarative) hardcoded IP addresses or subnet masks
```
./cnf-conformance ip_addresses
```
#### :heavy_check_mark: To test if there are node ports used in the service configuration
```
./cnf-conformance nodeport_not_used
```
#### :heavy_check_mark: To test if there are any (non-declarative) hardcoded IP addresses or subnet masks in the K8s runtime configuration
```
./cnf-conformance hardcoded_ip_addresses_in_k8s_runtime_configuration
```

#### :heavy_check_mark: To check if a CNF version can be downgraded through a rolling_downgrade 
```
./cnf-conformance rolling_downgrade
```

#### :heavy_check_mark: To check if a CNF version can be rolled back [rollback](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#rolling-back-a-deployment)
```
./cnf-conformance rollback
```
#### :heavy_check_mark: To check if a CNF uses K8s secrets
```
./cnf-conformance secrets_used
```
##Additional information##
Rules for the test:
The whole test passes if *any* workload resource in the cnf uses a (non-exempt) secret. 
If no workload resources use a (non-exempt) secret, the test is skipped.  

#### :heavy_check_mark: To check if a CNF version uses [immutable configmaps](https://kubernetes.io/docs/concepts/configuration/configmap/#configmap-immutable)
```
./cnf-conformance immutable_configmaps
```

<details> <summary>Details for Configuration and Lifecycle Tests To Do's</summary>
<p>

#### :memo: (To Do) To test if the CNF is installed with a versioned Helm v3 Chart
```
crystal src/cnf-conformance.cr versioned_helm_chart
```
#### :memo: (To Do) Test starting a container without mounting a volume that has configuration files
```
crystal src/cnf-conformance.cr no_volume_with_configuration
```
#### :memo: (To Do) To test if the CNF responds properly [when being restarted](//https://github.com/litmuschaos/litmus)
```
crystal src/cnf-conformance.cr reset_cnf
```
#### :memo: (To Do) To test if, when parent processes are restarted, the [child processes](https://github.com/falcosecurity/falco) are [reaped](https://github.com/draios/sysdig-inspect)
```
crystal src/cnf-conformance.cr check_reaped
```

</p>
</details>

---
### Observability Tests
#### :heavy_check_mark: To run all observability tests
```
./cnf-conformance observability
```

<details> <summary>Details for Observability Tests To Do's</summary>
<p>

#### :memo: (To Do) Test if there traffic to Fluentd
```
crystal src/cnf-conformance.cr fluentd_traffic
```
#### :memo: (To Do) Test if there is traffic to Jaeger
```
crystal src/cnf-conformance.cr jaeger_traffic
```
#### :memo: (To Do) Test if there is traffic to Prometheus
```
crystal src/cnf-conformance.cr prometheus traffic
```
#### :memo: (To Do) Test if tracing calls are compatible with [OpenTelemetry](https://opentracing.io/) 
```
crystal src/cnf-conformance.cr opentelemetry_compatible
```
#### :memo: (To Do) Test are if the monitoring calls are compatible with [OpenMetric](https://github.com/OpenObservability/OpenMetrics) 
```
crystal src/cnf-conformance.cr openmetric_compatible
```
</p>
</details>

---
### Installable and Upgradeable Tests
#### :heavy_check_mark: To run all installability tests
```
./cnf-conformance installability
```

#### :heavy_check_mark: Test if the Helm chart is published
```
./cnf-conformance helm_chart_published
```
#### :heavy_check_mark: Test if the [Helm chart is valid](https://github.com/helm/chart-testing))
```
./cnf-conformance helm_chart_valid
```
#### :heavy_check_mark: Test if the Helm deploys
Use a cnf-conformance.yml to manually call helm_deploy, e.g.:
Copy your CNF into the `cnfs` directory:
```
cp -rf <your-cnf-directory> cnfs/<your-cnf-directory>
```
Now run the test:
```
./cnf-conformance helm_deploy destructive cnfs/<your-cnf-directory>/cnf-conformance.yml
```
#### :heavy_check_mark: Test if the install script uses [Helm v3](https://github.com/helm/)
```
./cnf-conformance install_script_helm
```

#### :heavy_check_mark: To test if the CNF can perform a [rolling update](https://kubernetes.io/docs/tasks/run-application/rolling-update-replication-controller/)
```
./cnf-conformance rolling_update
```

---
### Hardware Resources and Scheduling Tests
#### :heavy_check_mark: Run all hardware resources and scheduling tests
```
crystal src/cnf-conformance.cr hardware_and_scheduling

```
<details> <summary>Details for Hardware and Scheduling Tests To Do's</summary>
<p>

#### :memo: (To Do) Test if the CNF is accessing hardware in its configuration files
```
crystal src/cnf-conformance.cr static_accessing_hardware
```
#### :memo: (To Do) Test if the CNF is accessing hardware directly during run-time (e.g. accessing the host /dev or /proc from a mount)
```
crystal src/cnf-conformance.cr dynamic_accessing_hardware
```
#### :memo: (To Do) Test if the CNF is accessing hugepages directly instead of via [Kubernetes resources](https://github.com/cncf/cnf-testbed/blob/c4458634deca5e8ab73adf118eedde32904c8458/examples/use_case/external-packet-filtering-on-k8s-nsm-on-packet/gateway.yaml#L29)
```
crystal src/cnf-conformance.cr direct_hugepages
```
#### :memo: (To Do) Test if the CNF Testbed performance output shows adequate throughput and sessions using the [CNF Testbed](https://github.com/cncf/cnf-testbed) (vendor neutral) hardware environment
```
crystal src/cnf-conformance.cr performance
```
</p>
</details>

---
### Resilience Tests
#### :heavy_check_mark: To run all resilience tests
```
./cnf-conformance resilience
```
#### :heavy_check_mark: Test if the CNF crashes when network loss occurs
```
./cnf-conformance chaos_network_loss
```
#### :heavy_check_mark: Test if the CNF crashes under high CPU load 
```
./cnf-conformance chaos_cpu_hog 
```
#### :heavy_check_mark: Test if the CNF restarts after container is killed 
```
./cnf-conformance chaos_container_kill
```
#### :heavy_check_mark: Test if the CNF crashes when network latency occurs 
```
./cnf-conformance pod_network_latency
```

#### :heavy_check_mark: Test if the CNF crashes when disk fill occurs 
```
./cnf-conformance disk_fill
```

---
### Platform Tests
####  :heavy_check_mark: Run all platform tests
```
./cnf-conformance platform
```
####  :heavy_check_mark: Run the K8s conformance tests
```
./cnf-conformance  k8s_conformance
```
####  :heavy_check_mark: Run All platform harware and scheduling tests 
```
./cnf-conformance  platform:hardware_and_scheduling
```
#### :heavy_check_mark: Run runtime compliance test
```
./cnf-conformance platform:oci_compliant
```
#### Proof of Concepts for Platform Tests
##### :bulb: (PoC) Run All platform resilience tests 
```
./cnf-conformance platform:resilience poc
```
##### :bulb: (PoC) Run All platform observability tests 
```
./cnf-conformance platform:observability poc
```
##### :x: :bulb: (PoC) Run node failure test. WARNING this is a destructive test and will reboot your *host* node!

##### Do not run this unless you have completely separate cluster, e.g. development or test cluster.
```
./cnf-conformance platform:node_failure poc destructive
```
