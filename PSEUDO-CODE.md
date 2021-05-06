# CNF TestSuite Psuedo code

## Compatibility Tests

####  To check of the CNF's CNI plugin accepts valid calls from the [CNI specification](https://github.com/containernetworking/cni/blob/master/SPEC.md)
```
pseudo code
```
####  To check for the use of alpha K8s API endpoints
```
pseudo code
```
####  To check for the use of beta K8s API endpoints
```
pseudo code
```
####  To check for the use of generally available (GA) K8s API endpoints
```
curl https://raw.githubusercontent.com/cncf/apisnoop/master/deployment/k8s/kind-cluster-config.yaml -o kind-cluster-config.yaml
kind create cluster --name kind-$USER --config kind-cluster-config.yaml
kubectl apply -f https://raw.githubusercontent.com/cncf/apisnoop/master/deployment/k8s/raiinbow.yaml
```

## Statelessness Tests

####  To test if the CNF responds properly [when being restarted](//https://github.com/litmuschaos/litmus)
```
pseudo code
```
####  To test if, when parent processes are restarted, the [child processes](https://github.com/falcosecurity/falco) are [reaped](https://github.com/draios/sysdig-inspect)
```
pseudo code
```

## Security Tests

####  To check if any containers are running in [privileged mode](https://github.com/open-policy-agent/gatekeeper)
```
kubectl get pods --all-namespaces -o jsonpath='{.items[*].spec.containers[?(@.securityContext.privileged==true)].name}'
# Alternatively
docker run --rm -it ubuntu ip link add dummy0 type dummy 
RTNETLINK answers: Operation not permitted
```
####  To check if there are any [shells running in the container](https://github.com/open-policy-agent/gatekeeper)
```
pseudo code
```
#### To check if there are any [protected directories](https://github.com/open-policy-agent/gatekeeper) or files that are accessed from within the container
```
pseudo code
```

## Scalability Tests

####  To test the [increasing and decreasing of capacity](https://kubernetes.io/docs/reference/kubectl/cheatsheet/#scaling-resources)
```
kubectl scale --replicas=3 rs/foo
```
####  To test small scale autoscaling
```
kubectl scale --replicas=3 rs/foo
```
####  To test [large scale autoscaling](https://github.com/cncf/cnf-testbed)
```
pseudo code
```
####  To test if the CNF responds to [network](https://github.com/alexei-led/pumba) [chaos](https://github.com/worstcase/blockade)
```
pseudo code
```

####  To test if the CNF control layer uses [external retry logic](https://github.com/envoyproxy/envoy)
```
pseudo code
```

## Configuration and Lifecycle Tests

####  To test if the CNF is installed with a versioned Helm v3 Chart
```
pseudo code
```
####  To test if there are any (non-declarative) hardcoded IP addresses or subnet masks
```
grep --exclude-dir={} --exclude=*.o -rnw '.' -e '.*(?:\d{1,3}\.){3}\d{1,3}*' 
```
####  To test if there is a liveness entry in the Helm chart
```
yq read deployment.yaml spec.template.spec.containers.0.livenessProbe 
```
####  To test if there is a readiness entry in the Helm chart
```
yq read deployment.yaml spec.template.spec.containers.0.readinessProbe 
```
####  Test starting a container without mounting a volume that has configuration files
```
pseudo code
```
####  To test if the CNF responds properly [when being restarted](//https://github.com/litmuschaos/litmus)
```
pseudo code
```
####  To test if, when parent processes are restarted, the [child processes](https://github.com/falcosecurity/falco) are [reaped](https://github.com/draios/sysdig-inspect)
```
pseudo code
```
####  To test if the CNF can perform a [rolling update](https://kubernetes.io/docs/tasks/run-application/rolling-update-replication-controller/)
```
kubectl rolling-update
```

## Observability Tests

####  Test if there is traffic to Fluentd
```
pseudo code
```
####  Test if there is traffic to Jaeger
```
pseudo code
```
####  Test if [Prometheus](https://github.com/prometheus/prometheus) is [configured correctly](https://prometheus.io/docs/prometheus/latest/configuration/unit_testing_rules/)
```
pseudo code
```
####  Test if there is traffic to Prometheus
```
pseudo code
```
####  Test if tracing calls are compatible with [OpenTelemetry](https://opentracing.io/) 
```
pseudo code
```
####  Test are if the monitoring calls are compatible with [OpenMetric](https://github.com/OpenObservability/OpenMetrics) 
```
pseudo code
```

## Installable and Upgradeable Tests

####  Test if the install script uses [Helm v3](https://github.com/helm/)
```
pseudo code
```
####  Test if the Helm chart is published to a public helm chart repository
```
helm repo add
```
####  Test if the [Helm chart is valid](https://github.com/helm/chart-testing))
```
pseudo code
```
####  Test if the CNF can perform a [rolling update](https://kubernetes.io/docs/tasks/run-application/rolling-update-replication-controller/)
```
pseudo code
```

## Hardware Resources and Scheduling Tests

####  Test if the CNF is accessing hardware in its configuration files
```
pseudo code
```
####  Test if the CNF is accessing hardware directly during run-time (e.g. accessing the host /dev or /proc from a mount)
```
pseudo code
```
####  Test if the CNF is accessing hugepages directly instead of via [Kubernetes resources](https://github.com/cncf/cnf-testbed/blob/c4458634deca5e8ab73adf118eedde32904c8458/examples/use_case/external-packet-filtering-on-k8s-nsm-on-packet/gateway.yaml#L29)
```
pseudo code
```
####  Test if the CNF Testbed performance output shows adequate throughput and sessions using the [CNF Testbed](https://github.com/cncf/cnf-testbed) (vendor neutral) hardware environment
```
pseudo code
```
                                                                                                                                                                                                  
