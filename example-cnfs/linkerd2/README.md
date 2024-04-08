# What is [Linkerd](https://linkerd.io/)?

Linkerd is a service mesh, designed to give platform-wide observability, reliability, and security without requiring configuration or code changes.

## Pre-req:

Follow [Pre-req steps](../../INSTALL.md#pre-requisites), including
Set the KUBECONFIG environment to point to the remote K8s cluster

### Automated Linkerd installation

Run cnf-testsuite setup

```
./cnf-testsuite setup
```

Install linkerd

```
./linkerd_install.sh

helm repo add linkerd https://helm.linkerd.io/stable

helm install linkerd-crds linkerd/linkerd-crds -n linkerd --create-namespace 

.cnf-testsuite cnf_setup cnf-path=example-cnfs/linkerd2/cnf-testsuite.yml
```

Run the test suite:

```
./cnf-testsuite all
```

linkerd cleanup

```
./cnf-testsuite cnf_cleanup cnf-path=example-cnfs/linkerd2/cnf-testsuite.yml
```
