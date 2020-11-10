# CNF Conformance Test CLI Usage Documentation 

The CNF Conformance Test suite can be run in developer mode (using crystal lang directly) or in production mode (using an executable).  See the [pseudo code documentation](https://github.com/cncf/cnf-conformance/blob/master/PSEUDO-CODE.md) for examples of how the internals of WIP tests might work.

### Syntax for running any of the tests
```
# Developer mode
crystal src/cnf-conformance.cr <testname>

# Production mode
./cnf-conformance <testname>
```

### Validating a cnf-conformance.yml file
```
# Developer mode
crystal src/cnf-conformance.cr validate_config cnf-config=[PATH_TO]/cnf-conformance.yml

# Production mode
./cnf-conformance validate_config cnf-config=[PATH_TO]/cnf-conformance.yml
```

### Building the executable
```
crystal build src/cnf-conformance.cr
```
## Running all of the CNF Conformance tests (platform and workload)
``` 
crystal src/cnf-conformance.cr all cnf-config=<path_to_your_config_file>/cnf-conformance.yml
```

## Running all of the CNF Conformance tests (including proofs of concepts)
``` 
crystal src/cnf-conformance.cr all poc cnf-config=<path_to_your_config_file>/cnf-conformance.yml
```
## Running all of the workload CNF Conformance tests
``` 
crystal src/cnf-conformance.cr workload
cnf-config=<path_to_your_config_file>/cnf-conformance.yml
```

## Running all of the platform CNF Conformance tests
``` 
crystal src/cnf-conformance.cr platform
```
## Logging 

```
# cmd line
./cnf-conformance -l debug test

# make sure to use -- if running from source
crystal src/cnf-conformance.cr -- -l debug test 

# env var
LOGLEVEL=DEBUG ./cnf-conformance test
```

NOTE: When setting log level precedence highest of following wins 

1. Cli flag is highest precedence
2. Environment var is next level of precedence
3. [Config file](https://github.com/cncf/cnf-conformance/blob/master/config.yml) is last level of precedence

Also setting the verbose option for many tasks will add extra output to help with debugging

```
crystal src/cnf-conformance.cr test_name verbose
```

### Running The Linter

https://github.com/crystal-ameba/ameba

```
shards install # only for first install
crystal bin/ameba.cr
```
## To see a list of all tasks in the test suite

``` 
crystal src/cnf-conformance.cr help 
```


## Compatibility Tests

#### :heavy_check_mark: To run all of the compatibility tests
```
crystal src/cnf-conformance.cr compatibility
```
#### (To Do) To check of the CNF's CNI plugin accepts valid calls from the [CNI specification](https://github.com/containernetworking/cni/blob/master/SPEC.md)
```
crystal src/cnf-conformance.cr cni_spec
```
#### (To Do) To check for the use of alpha K8s API endpoints
```
crystal src/cnf-conformance.cr api_snoop_alpha
```
#### (To Do) To check for the use of beta K8s API endpoints
```
crystal src/cnf-conformance.cr api_snoop_beta
```
#### (To Do) To check for the use of generally available (GA) K8s API endpoints
```
crystal src/cnf-conformance.cr api_snoop_general_apis
```


## Statelessness Tests
#### :heavy_check_mark: To run all of the statelessness tests
```
crystal src/cnf-conformance.cr stateless
```
#### (To Do) To test if the CNF responds properly [when being restarted](//https://github.com/litmuschaos/litmus)
```
crystal src/cnf-conformance.cr reset_cnf
```
#### (To Do) To test if, when parent processes are restarted, the [child processes](https://github.com/falcosecurity/falco) are [reaped](https://github.com/draios/sysdig-inspect)
```
crystal src/cnf-conformance.cr check_reaped
```
#### :heavy_check_mark:  To test if the CNF uses a volume host path
```
crystal src/cnf-conformance.cr volume_hostpath_not_found 
```

## Security Tests
#### :heavy_check_mark: To run all of the security tests
```
crystal src/cnf-conformance.cr security
```

#### :heavy_check_mark: To check if any containers are running in [privileged mode](https://github.com/open-policy-agent/gatekeeper)
```
crystal src/cnf-conformance.cr privileged
```
#### (To Do) To check if there are any [shells running in the container](https://github.com/open-policy-agent/gatekeeper)
```
crystal src/cnf-conformance.cr shells
```
#### [To Do] To check if there are any [protected directories](https://github.com/open-policy-agent/gatekeeper) or files that are accessed from within the container
```
crystal src/cnf-conformance.cr protected_access
```

## Microservice Tests
#### :heavy_check_mark: To run all of the microservice tests
```
crystal src/cnf-conformance.cr microservice
```

#### :heavy_check_mark: To check if the CNF has a reasonable image size
```
crystal src/cnf-conformance.cr reasonable_image_size
```
#### :heavy_check_mark: To check if the CNF have a reasonable startup time
```
crystal src/cnf-conformance.cr reasonable_startup_time
```


## Scalability Tests

#### :heavy_check_mark: To run all of the scalability tests
```
crystal src/cnf-conformance.cr scalability
```

#### :heavy_check_mark: To test the [increasing and decreasing of capacity](https://kubernetes.io/docs/reference/kubectl/cheatsheet/#scaling-resources)
Optional: To install the sample coredns cnf:

```
crystal src/cnf-conformance.cr sample_coredns_setup helm_chart=<helm chart name>
# Or optionally modify the your cnf's cnf-conformance.yml file to include the helm_chart name
# e.g. 
helm_chart: stable/coredns
```
To run the capacity test
```
crystal src/cnf-conformance.cr increase_decrease_capacity deployment_name=coredns-coredns
# Or optionally modify the your cnf's cnf-conformance.yml file to include the deployment name
# e.g. 
deployment_name: coredns/coredns 
```
#### (To Do) To test small scale autoscaling
```
crystal src/cnf-conformance.cr small_autoscaling
```
#### (To Do) To test [large scale autoscaling](https://github.com/cncf/cnf-testbed)
```
crystal src/cnf-conformance.cr large_autoscaling
```
#### (To Do) To test if the CNF responds to [network](https://github.com/alexei-led/pumba) [chaos](https://github.com/worstcase/blockade)
```
crystal src/cnf-conformance.cr network_chaos
```

#### (To Do) To test if the CNF control layer uses [external retry logic](https://github.com/envoyproxy/envoy)
```
crystal src/cnf-conformance.cr external_retry
```

## Configuration and Lifecycle Tests
#### :heavy_check_mark: To run all of the configuration and lifecycle tests
```
crystal src/cnf-conformance.cr configuration_lifecycle
```

#### (To Do) To test if the CNF is installed with a versioned Helm v3 Chart
```
crystal src/cnf-conformance.cr versioned_helm_chart
```
#### :heavy_check_mark: To test if there are any (non-declarative) hardcoded IP addresses or subnet masks
```
crystal src/cnf-conformance.cr ip_addresses
```
#### :heavy_check_mark: To test if there are node ports used in the service configuration
```
crystal src/cnf-conformance.cr nodeport_not_used
```
#### :heavy_check_mark: To test if there are any (non-declarative) hardcoded IP addresses or subnet masks in the K8s runtime configuration
```
crystal src/cnf-conformance.cr hardcoded_ip_addresses_in_k8s_runtime_configuration
```
#### (PoC) To test if there is a liveness entry in the Helm chart
```
crystal src/cnf-conformance.cr liveness
```
#### (PoC) To test if there is a readiness entry in the Helm chart
```
crystal src/cnf-conformance.cr readiness
```
#### (To Do) Test starting a container without mounting a volume that has configuration files
```
crystal src/cnf-conformance.cr no_volume_with_configuration
```
#### (To Do) To test if the CNF responds properly [when being restarted](//https://github.com/litmuschaos/litmus)
```
crystal src/cnf-conformance.cr reset_cnf
```
#### (To Do) To test if, when parent processes are restarted, the [child processes](https://github.com/falcosecurity/falco) are [reaped](https://github.com/draios/sysdig-inspect)
```
crystal src/cnf-conformance.cr check_reaped
```
#### (To Do) To test if the CNF can perform a [rolling update](https://kubernetes.io/docs/tasks/run-application/rolling-update-replication-controller/)
```
crystal src/cnf-conformance.cr rolling_update
```

## Observability Tests
#### :heavy_check_mark: To run all observability tests
```
crystal src/cnf-conformance.cr observability
```
#### (To Do) Test if there traffic to Fluentd
```
crystal src/cnf-conformance.cr fluentd_traffic
```
#### (To Do) Test if there is traffic to Jaeger
```
crystal src/cnf-conformance.cr jaeger_traffic
```
#### (To Do) Test if there is traffic to Prometheus
```
crystal src/cnf-conformance.cr prometheus traffic
```
#### (To Do) Test if tracing calls are compatible with [OpenTelemetry](https://opentracing.io/) 
```
crystal src/cnf-conformance.cr opentelemetry_compatible
```
#### (To Do) Test are if the monitoring calls are compatible with [OpenMetric](https://github.com/OpenObservability/OpenMetrics) 
```
crystal src/cnf-conformance.cr openmetric_compatible
```

## Installable and Upgradeable Tests
#### :heavy_check_mark: To run all installability tests
```
crystal src/cnf-conformance.cr installability
```
#### (PoC) Test if the install script uses [Helm v3](https://github.com/helm/)
```
crystal src/cnf-conformance.cr install_script_helm
```
#### :heavy_check_mark: Test if the Helm chart is published
```
crystal src/cnf-conformance.cr helm_chart_published
```
#### :heavy_check_mark: Test if the [Helm chart is valid](https://github.com/helm/chart-testing))
```
crystal src/cnf-conformance.cr helm_chart_valid
```
#### :heavy_check_mark: Test if the Helm deploys
```
# Use a cnf-conformance.yml to manually call helm_deploy
# e.g. cp -rf <your-cnf-directory> cnfs/<your-cnf-directory>
crystal src/cnf-conformance.cr helm_deploy cnfs/<your-cnf-directory>/cnf-conformance.yml
```
#### (To Do) To test if the CNF can perform a [rolling update](https://kubernetes.io/docs/tasks/run-application/rolling-update-replication-controller/)
```
crystal src/cnf-conformance.cr rolling_update
```

## Hardware Resources and Scheduling Tests
#### :heavy_check_mark: Run all hardware resources and scheduling tests
```
crystal src/cnf-conformance.cr hardware_and_scheduling
```

#### (To Do) Test if the CNF is accessing hardware in its configuration files
```
crystal src/cnf-conformance.cr static_accessing_hardware
```
#### (To Do) Test if the CNF is accessing hardware directly during run-time (e.g. accessing the host /dev or /proc from a mount)
```
crystal src/cnf-conformance.cr dynamic_accessing_hardware
```
#### (To Do) Test if the CNF is accessing hugepages directly instead of via [Kubernetes resources](https://github.com/cncf/cnf-testbed/blob/c4458634deca5e8ab73adf118eedde32904c8458/examples/use_case/external-packet-filtering-on-k8s-nsm-on-packet/gateway.yaml#L29)
```
crystal src/cnf-conformance.cr direct_hugepages
```
#### (To Do) Test if the CNF Testbed performance output shows adequate throughput and sessions using the [CNF Testbed](https://github.com/cncf/cnf-testbed) (vendor neutral) hardware environment
```
crystal src/cnf-conformance.cr performance
```

## Resilience Tests
#### :heavy_check_mark: To run all resilience tests
```
crystal src/cnf-conformance.cr resilience
```
#### :heavy_check_mark: Test if the CNF crashes when network loss occurs
```
crystal src/cnf-conformance.cr chaos_network_loss
```
#### :heavy_check_mark: Test if the CNF crashes under high CPU load 
```
crystal src/cnf-conformance.cr chaos_cpu_hog 
```
#### :heavy_check_mark: Test if the CNF restarts after container is killed 
```
crystal src/cnf-conformance.cr chaos_container_kill
```

## Platform Tests
####  :heavy_check_mark: Run all platform tests
```
crystal src/cnf-conformance.cr platform
```
####  :heavy_check_mark: Run the K8s conformance tests
```
crystal src/cnf-conformance.cr k8s_conformance
```
####  :heavy_check_mark: Run All platform harware and scheduling tests 
```
crystal src/cnf-conformance.cr platform:hardware_and_scheduling poc
```
#### :heavy_check_mark: Run runtime compliance test
```
crystal src/cnf-conformance.cr platform:oci_compliant

```
#### (PoC) Run All platform resilience tests 
```
crystal src/cnf-conformance.cr platform:resilience poc

```
#### (PoC) Run All platform observability tests 
```
crystal src/cnf-conformance.cr platform:observability poc

```
#### (PoC) Run node failure test **warning** this is a destructive test and will reboot your *host* node!
#### Don't run this unless you have completely separate cluster (e.g. you are not running KIND on a dev box)
```
crystal src/cnf-conformance.cr platform:node_failure poc destructive
```


