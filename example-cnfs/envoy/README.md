# What is [Envoy](https://www.envoyproxy.io/)?
Envoy is a programmable L3/L4 and L7 proxy that powers today’s service mesh 
solutions including Istio, AWS App Mesh, Consul Connect, etc. At Envoy’s core 
lie several filters that provide a rich set of features for observing, securing, 
and routing network traffic to microservices

## Pre-req:
Follow [Pre-req steps](https://github.com/cncf/cnf-conformance/blob/main/INSTALL.md#prerequisites), including
Set the KUBECONFIG environment to point to the remote K8s cluster

### Automated Envoy installation
Run cnf-conformance setup 
```
crystal src/cnf-conformance.cr setup
```

Add the published helm chart: 
```
crystal src/cnf-conformance.cr helm_repo_add  cnf-config=example-cnfs/envoy/cnf-conformance.yml
```

Install Envoy 
```
crystal src/cnf-conformance.cr cnf_setup cnf-path=example-cnfs/envoy
```

Run the conformance suite: 
```
crystal src/cnf-conformance.cr all
```

Envoy cleanup
```
crystal src/cnf-conformance.cr cnf_cleanup cnf-path=example-cnfs/envoy
```
  
