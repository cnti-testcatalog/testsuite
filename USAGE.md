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
#### (WIP) To run [K8s conformance](https://github.com/cncf/k8s-conformance/blob/master/instructions.md)
```
crystal src/cnf-conformance.cr k8s_conformance
```
#### (WIP) To run K8s API testing for ensuring the use of generally available endpoints
```
crystal src/cnf-conformance.cr api_snoop_general_apis
```
#### (WIP) To run [K8s API testing](https://github.com/cncf/apisnoop) for checking for the use of beta endpoints
```
crystal src/cnf-conformance.cr api_snoop_beta
```
#### (WIP) To check of the CNF's CNI plugin accepts valid calls from the [CNI specification](https://github.com/containernetworking/cni/blob/master/SPEC.md)
```
crystal src/cnf-conformance.cr cni_spec
```
## Stateless Tests
#### :heavy_check_mark: To run all of the stateless tests
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

## Scaling Tests

#### :heavy_check_mark: To run all of the scaling tests
```
crystal src/cnf-conformance.cr scaling
```

#### :heavy_check_mark To test the [increasing and decreasing of capacity](https://kubernetes.io/docs/reference/kubectl/cheatsheet/#scaling-resources)
Optional: To install the sample coredns cnf:

```
crystal src/cnf-conformance.cr sample_coredns_setup helm_chart=<helm chart name>
# Or optionally add a helm_chart entry to the config.yml 
# e.g. 
helm_chart: stable/coredns
```
To run the capacity test
```
crystal src/cnf-conformance.cr increase_decrease_capacity deployment_name=coredns-coredns
# Or optionally modify the config.yml file to include the deployment name
# e.g. 
deployment_name: coredns/coredns 
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

#### (WIP) To test if the CNF control layer using [external retry logic](https://github.com/envoyproxy/envoy)
```
crystal src/cnf-conformance.cr external_retry
```

## Configuration and Lifecycle Tests
#### :heavy_check_mark: To run all of the configuration and lifecycle tests
```
crystal src/cnf-conformance.cr configuration_lifecycle
```

#### (WIP) To test if the CNF is installed with a versioned Helm Chart
```
crystal src/cnf-conformance.cr versioned_helm_chart
```
#### :heavy_check_mark: To test if there are any (non-declarative) hardcoded ip addresses or subnet masks
```
crystal src/cnf-conformance.cr ip_addresses
```
#### :heavy_check_mark: To test if there is a liveness entry in the helm chart
```
crystal src/cnf-conformance.cr liveness
```
#### :heavy_check_mark: To test if there is a readiness entry in the helm chart
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

#### (WIP) Test if [Fluentd](https://github.com/fluent/fluentd) is installed in the cluster?
```
crystal src/cnf-conformance.cr fluentd_exists
```
#### (WIP) Test if there traffic to Fluentd
```
crystal src/cnf-conformance.cr fluentd_traffic
```
#### (WIP) Test if [Jaeger](https://github.com/jaegertracing/jaeger) is installed in the cluster
```
crystal src/cnf-conformance.cr jaeger_installed
```
#### (WIP) Test if there is traffic to Jaeger
```
crystal src/cnf-conformance.cr jaeger_traffic
```
#### (WIP) Test if [Prometheus](https://github.com/prometheus/prometheus) is installed in the cluster and [configured correctly](https://prometheus.io/docs/prometheus/latest/configuration/unit_testing_rules/)
```
crystal src/cnf-conformance.cr prometheus_installed
```
#### (WIP) Test if there is traffic to Prometheus
```
crystal src/cnf-conformance.cr prometheus traffic
```
#### (WIP) Test if tracing calls are [OpenTelemetry](https://opentracing.io/) compatible
```
crystal src/cnf-conformance.cr opentelemetry_compatible
```
#### (WIP) Test are if the monitoring calls are [OpenMetric](https://github.com/OpenObservability/OpenMetrics) compatible
```
crystal src/cnf-conformance.cr openmetric_compatible
```

## Installable and Upgradeable
#### :heavy_check_mark: To run all installability tests
```
crystal src/cnf-conformance.cr installability
```
#### :heavy_check_mark: Test if the install script uses [Helm](https://github.com/helm/)
```
crystal src/cnf-conformance.cr install_script_helm
```
#### :heavy_check_mark: Test if the [Helm chart is valid](https://github.com/helm/chart-testing))
```
crystal src/cnf-conformance.cr helm_chard_valid
```
#### (WIP) To test if the CNF can perform a [rolling update](https://kubernetes.io/docs/tasks/run-application/rolling-update-replication-controller/)
```
crystal src/cnf-conformance.cr rolling_update
```

## Hardware and Affinity support
#### :heavy_check_mark: Run all hardware and affinity tests
```
crystal src/cnf-conformance.cr hardware_affinity
```

#### (WIP) Test if the CNF is accessing hardware in its configuration files
```
crystal src/cnf-conformance.cr static_accessing_hardware
```
#### (WIP) Test if the CNF accessess hardware directly during run-time (e.g. accessing the host /dev or /proc from a mount)
```
crystal src/cnf-conformance.cr dynamic_accessing_hardware
```
#### (WIP) Test if the CNF accessess hugepages directly instead of via [Kubernetes resources](https://github.com/cncf/cnf-testbed/blob/c4458634deca5e8ab73adf118eedde32904c8458/examples/use_case/external-packet-filtering-on-k8s-nsm-on-packet/gateway.yaml#L29)
```
crystal src/cnf-conformance.cr direct_hugepages
```
#### (WIP) Test if the cnf testbed performance output shows adequate throughput and sessions using the [CNF Testbed](https://github.com/cncf/cnf-testbed) (vendor neutral) hardware environment
```
crystal src/cnf-conformance.cr performance
```
                                                                                                                                                                                                  
