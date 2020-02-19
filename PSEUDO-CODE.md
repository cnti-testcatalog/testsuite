# CNF Conformance Test Psuedo code

## Compatibility Tests

####  To run [K8s conformance](https://github.com/cncf/k8s-conformance/blob/master/instructions.md)

```
go get -u -v github.com/heptio/sonobuoy
sonobuoy run --mode=certified-conformance
sonobuoy status
sonobuoy logs

```
####  To run K8s API testing for ensuring the use of generally available endpoints
```
curl https://raw.githubusercontent.com/cncf/apisnoop/master/deployment/k8s/kind-cluster-config.yaml -o kind-cluster-config.yaml
kind create cluster --name kind-$USER --config kind-cluster-config.yaml
kubectl apply -f https://raw.githubusercontent.com/cncf/apisnoop/master/deployment/k8s/raiinbow.yaml

```
####  To run [K8s API testing](https://github.com/cncf/apisnoop) for checking for the use of beta endpoints
```
psuedo code
```
####  To check of the CNF's CNI plugin accepts valid calls from the [CNI specification](https://github.com/containernetworking/cni/blob/master/SPEC.md)
```
psuedo code
```
## Stateless Tests

####  To test if the CNF responds properly [when being restarted](//https://github.com/litmuschaos/litmus)
```
psuedo code
```
####  To test if, when parent processes are restarted, the [child processes](https://github.com/falcosecurity/falco) are [reaped](https://github.com/draios/sysdig-inspect)
```
psuedo code
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
psuedo code
```
#### To check if there are any [protected directories](https://github.com/open-policy-agent/gatekeeper) or files that are accessed from within the container
```
psuedo code
```

## Scaling Tests

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
psuedo code
```
####  To test if the CNF responds to [network](https://github.com/alexei-led/pumba) [chaos](https://github.com/worstcase/blockade)
```
psuedo code
```

####  To test if the CNF control layer using [external retry logic](https://github.com/envoyproxy/envoy)
```
psuedo code
```

## Configuration and Lifecycle Tests

####  To test if the CNF is installed with a versioned Helm Chart
```
psuedo code
```
####  To test if there are any (non-declarative) hardcoded ip addresses or subnet masks
```
grep --exclude-dir={} --exclude=*.o -rnw '.' -e '.*(?:\d{1,3}\.){3}\d{1,3}*' 
```
####  To test if there is a liveness entry in the helm chart
```
yq read deployment.yaml spec.template.spec.containers.0.livenessProbe 
```
####  To test if there is a readiness entry in the helm chart
```
yq read deployment.yaml spec.template.spec.containers.0.readinessProbe 
```
####  Test starting a container without mounting a volume that has configuration files
```
psuedo code
```
####  To test if the CNF responds properly [when being restarted](//https://github.com/litmuschaos/litmus)
```
psuedo code
```
####  To test if, when parent processes are restarted, the [child processes](https://github.com/falcosecurity/falco) are [reaped](https://github.com/draios/sysdig-inspect)
```
psuedo code
```
####  To test if the CNF can perform a [rolling update](https://kubernetes.io/docs/tasks/run-application/rolling-update-replication-controller/)
```
kubectl rolling-update
```

## Observability Tests

####  Test if [Fluentd](https://github.com/fluent/fluentd) is installed in the cluster?
```
psuedo code
```
####  Test if there traffic to Fluentd
```
psuedo code
```
####  Test if [Jaeger](https://github.com/jaegertracing/jaeger) is installed in the cluster
```
psuedo code
```
####  Test if there is traffic to Jaeger
```
psuedo code
```
####  Test if [Prometheus](https://github.com/prometheus/prometheus) is installed in the cluster and [configured correctly](https://prometheus.io/docs/prometheus/latest/configuration/unit_testing_rules/)
```
psuedo code
```
####  Test if there is traffic to Prometheus
```
psuedo code
```
####  Test if tracing calls are [OpenTelemetry](https://opentracing.io/) compatible
```
psuedo code
```
####  Test are if the monitoring calls are [OpenMetric](https://github.com/OpenObservability/OpenMetrics) compatible
```
psuedo code
```

## Installable and Upgradeable

####  Test if the install script uses [Helm](https://github.com/helm/)
```
psuedo code
```
####  Test if the [Helm chart is valid](https://github.com/helm/chart-testing))
```
psuedo code
```
####  To test if the CNF can perform a [rolling update](https://kubernetes.io/docs/tasks/run-application/rolling-update-replication-controller/)
```
psuedo code
```

## Hardware and Affinity support

####  Test if the CNF is accessing hardware in its configuration files
```
psuedo code
```
####  Test if the CNF accessess hardware directly during run-time (e.g. accessing the host /dev or /proc from a mount)
```
psuedo code
```
####  Test if the CNF accessess hugepages directly instead of via [Kubernetes resources](https://github.com/cncf/cnf-testbed/blob/c4458634deca5e8ab73adf118eedde32904c8458/examples/use_case/external-packet-filtering-on-k8s-nsm-on-packet/gateway.yaml#L29)
```
psuedo code
```
####  Test if the cnf testbed performance output shows adequate throughput and sessions using the [CNF Testbed](https://github.com/cncf/cnf-testbed) (vendor neutral) hardware environment
```
psuedo code
```
                                                                                                                                                                                                  
