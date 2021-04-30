# What is [NSM](https://https://networkservicemesh.io//)

Network Service Mesh (NSM) is a novel approach solving complicated L2/L3 use cases in Kubernetes that are tricky to address with the existing Kubernetes Network Model. Inspired by Istio, Network Service Mesh maps the concept of a Service Mesh to L2/L3 payloads as part of an attempt to re-imagine NFV in a Cloud-native way.

# Prerequistes

Follow [Pre-req steps](../../INSTALL.md#pre-requisites), including

- Set the KUBECONFIG environment to point to the remote K8s cluster
- Downloading the binary cnf-conformance release

### Automated CNF installation

Initialize the conformance suite

```
crystal src/cnf-testsuite.cr setup
```

Configure and deploy NSM as the target CNF

```
crystal src/cnf-testsuite.cr cnf_setup cnf-config=./example-cnfs/nsm/cnf-conformance.yml deploy_with_chart=false
```

Run the all the tests

```
crystal src/cnf-testsuite.cr all
```

Check the results file

Cleanup the cnf test setup (including undeployment of NSM)

```
crystal src/cnf-testsuite.cr cnf_cleanup cnf-config=./example-cnfs/nsm/cnf-conformance.yml
```
