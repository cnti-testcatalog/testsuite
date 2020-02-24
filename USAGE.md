# CNF Conformance Test CLI Usage Documentation 

The CNF Conformance Test suite can be run in developer mode (using crystal lang directly) or in production mode (using an executable).  See the [pseudo code documentation](https://github.com/cncf/cnf-conformance/blob/master/PSEUDO-CODE.md) for examples of how the internals of WIP tests might work.

### Syntax for running any of the tests
```
# Developer mode
crystal src/cnf-conformance.cr <testname>

# Production mode
./cnf-conformance <testname>
```
### Building the executable
```
crystal build src/cnf-conformance.cr
```
## Running all of the CNF Conformance tests
``` 
crystal src/cnf-conformance.cr all
```

## Compatibility Tests
#### :heavy_check_mark: To run all of the compatibility tests
```
crystal src/cnf-conformance.cr compatibility
```
#### (WIP) To check of the CNF's CNI plugin accepts valid calls from the [CNI specification](https://github.com/containernetworking/cni/blob/master/SPEC.md)
```
crystal src/cnf-conformance.cr cni_spec
```
#### (To Do) To run [K8s API testing](https://github.com/cncf/apisnoop) for checking for the use of alpha endpoints
```
pseudo code
```
#### (WIP) To run [K8s API testing](https://github.com/cncf/apisnoop) for checking for the use of beta endpoints
```
crystal src/cnf-conformance.cr api_snoop_beta
```
#### (WIP) To run [K8s API testing](https://github.com/cncf/apisnoop) for ensuring the use of generally available endpoints
```
crystal src/cnf-conformance.cr api_snoop_general_apis
```


## Statelessness Tests
#### :heavy_check_mark: To run all of the statelessness tests
```
crystal src/cnf-conformance.cr stateless
```
#### (WIP) To test if the CNF responds properly [when being restarted](//https://github.com/litmuschaos/litmus)
```
crystal src/cnf-conformance.cr reset_cnf
```
#### (WIP) To test if, when parent processes are restarted, the [child processes](https://github.com/falcosecurity/falco) are [reaped](https://github.com/draios/sysdig-inspect)
```
crystal src/cnf-conformance.cr check_reaped
```

## Security Tests
#### :heavy_check_mark: To run all of the security tests
```
crystal src/cnf-conformance.cr security
```

#### (WIP) To check if any containers are running in [privileged mode](https://github.com/open-policy-agent/gatekeeper)
```
crystal src/cnf-conformance.cr privileged
```
#### (WIP) To check if there are any [shells running in the container](https://github.com/open-policy-agent/gatekeeper)
```
crystal src/cnf-conformance.cr shells
```
#### [WIP] To check if there are any [protected directories](https://github.com/open-policy-agent/gatekeeper) or files that are accessed from within the container
```
crystal src/cnf-conformance.cr protected_access
```

## Scalability Tests

#### :heavy_check_mark: To run all of the scalability tests
```
crystal src/cnf-conformance.cr scaling
```

#### (WIP) To test the [increasing and decreasing of capacity](https://kubernetes.io/docs/reference/kubectl/cheatsheet/#scaling-resources)
```
crystal src/cnf-conformance.cr increase_decrease_capacity
```
#### (WIP) To test small scale autoscaling
```
crystal src/cnf-conformance.cr small_autoscaling
```
#### (WIP) To test [large scale autoscaling](https://github.com/cncf/cnf-testbed)
```
crystal src/cnf-conformance.cr large_autoscaling
```
#### (WIP) To test if the CNF responds to [network](https://github.com/alexei-led/pumba) [chaos](https://github.com/worstcase/blockade)
```
crystal src/cnf-conformance.cr network_chaos
```

#### (WIP) To test if the CNF control layer uses [external retry logic](https://github.com/envoyproxy/envoy)
```
crystal src/cnf-conformance.cr external_retry
```

## Configuration and Lifecycle Tests
#### :heavy_check_mark: To run all of the configuration and lifecycle tests
```
crystal src/cnf-conformance.cr configuration_lifecycle
```

#### (WIP) To test if the CNF is installed with a versioned Helm v3 Chart
```
crystal src/cnf-conformance.cr versioned_helm_chart
```
#### :heavy_check_mark: To test if there are any (non-declarative) hardcoded IP addresses or subnet masks
```
crystal src/cnf-conformance.cr ip_addresses
```
#### :heavy_check_mark: To test if there is a liveness entry in the Helm chart
```
crystal src/cnf-conformance.cr liveness
```
#### :heavy_check_mark: To test if there is a readiness entry in the Helm chart
```
crystal src/cnf-conformance.cr readiness
```
#### (WIP) Test starting a container without mounting a volume that has configuration files
```
crystal src/cnf-conformance.cr no_volume_with_configuration
```
#### (WIP) To test if the CNF responds properly [when being restarted](//https://github.com/litmuschaos/litmus)
```
crystal src/cnf-conformance.cr reset_cnf
```
#### (WIP) To test if, when parent processes are restarted, the [child processes](https://github.com/falcosecurity/falco) are [reaped](https://github.com/draios/sysdig-inspect)
```
crystal src/cnf-conformance.cr check_reaped
```
#### (WIP) To test if the CNF can perform a [rolling update](https://kubernetes.io/docs/tasks/run-application/rolling-update-replication-controller/)
```
crystal src/cnf-conformance.cr rolling_update
```

## Observability Tests
#### :heavy_check_mark: To run all observability tests
```
crystal src/cnf-conformance.cr observability
```
#### (WIP) Test if there traffic to Fluentd
```
crystal src/cnf-conformance.cr fluentd_traffic
```
#### (WIP) Test if there is traffic to Jaeger
```
crystal src/cnf-conformance.cr jaeger_traffic
```
#### (WIP) Test if there is traffic to Prometheus
```
crystal src/cnf-conformance.cr prometheus traffic
```
#### (WIP) Test if tracing calls are compatible with [OpenTelemetry](https://opentracing.io/) 
```
crystal src/cnf-conformance.cr opentelemetry_compatible
```
#### (WIP) Test are if the monitoring calls are compatible with [OpenMetric](https://github.com/OpenObservability/OpenMetrics) 
```
crystal src/cnf-conformance.cr openmetric_compatible
```

## Installable and Upgradeable Tests
#### :heavy_check_mark: To run all installability tests
```
crystal src/cnf-conformance.cr installability
```
#### :heavy_check_mark: Test if the install script uses [Helm v3](https://github.com/helm/)
```
crystal src/cnf-conformance.cr install_script_helm
```
#### (WIP) Test if the [Helm chart is valid](https://github.com/helm/chart-testing))
```
crystal src/cnf-conformance.cr helm_chard_valid
```
#### (WIP) To test if the CNF can perform a [rolling update](https://kubernetes.io/docs/tasks/run-application/rolling-update-replication-controller/)
```
crystal src/cnf-conformance.cr rolling_update
```

## Hardware Resources and Scheduling Tests
#### :heavy_check_mark: Run all hardware resources and scheduling tests
```
crystal src/cnf-conformance.cr hardware_affinity
```

#### (WIP) Test if the CNF is accessing hardware in its configuration files
```
crystal src/cnf-conformance.cr static_accessing_hardware
```
#### (WIP) Test if the CNF is accessing hardware directly during run-time (e.g. accessing the host /dev or /proc from a mount)
```
crystal src/cnf-conformance.cr dynamic_accessing_hardware
```
#### (WIP) Test if the CNF is accessing hugepages directly instead of via [Kubernetes resources](https://github.com/cncf/cnf-testbed/blob/c4458634deca5e8ab73adf118eedde32904c8458/examples/use_case/external-packet-filtering-on-k8s-nsm-on-packet/gateway.yaml#L29)
```
crystal src/cnf-conformance.cr direct_hugepages
```
#### (WIP) Test if the CNF Testbed performance output shows adequate throughput and sessions using the [CNF Testbed](https://github.com/cncf/cnf-testbed) (vendor neutral) hardware environment
```
crystal src/cnf-conformance.cr performance
```
                                                                                                                                                                                                  
