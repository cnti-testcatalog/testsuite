# What is [Envoy](https://www.envoyproxy.io/)?

Envoy is a programmable L3/L4 and L7 proxy that powers today’s service mesh
solutions including Istio, AWS App Mesh, Consul Connect, etc. At Envoy’s core
lie several filters that provide a rich set of features for observing, securing,
and routing network traffic to microservices

## Pre-req:

Follow [Pre-req steps](../../INSTALL.md#pre-requisites), including
Set the KUBECONFIG environment to point to the remote K8s cluster

### Automated Envoy installation

Run cnf-testsuite setup

```
crystal src/cnf-testsuite.cr setup
```

Add the published helm chart:

```
crystal src/cnf-testsuite.cr helm_repo_add  cnf-config=example-cnfs/envoy/cnf-testsuite.yml
```

Install Envoy

```
crystal src/cnf-testsuite.cr cnf_setup cnf-path=example-cnfs/envoy
```

Run the conformance suite:

```
crystal src/cnf-testsuite.cr all
```

Envoy cleanup

```
crystal src/cnf-testsuite.cr cnf_cleanup cnf-path=example-cnfs/envoy
```
