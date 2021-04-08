# What is [Linkerd](https://linkerd.io/)?
Linkerd is a service mesh, designed to give platform-wide observability, reliability, and security without requiring configuration or code changes.


## Pre-req:
Follow [Pre-req steps](https://github.com/cncf/cnf-conformance/blob/main/INSTALL.md#prerequisites), including
Set the KUBECONFIG environment to point to the remote K8s cluster

### Automated Envoy installation
Run cnf-conformance setup 
```
crystal src/cnf-conformance.cr setup
```

Install linkerd 
```
crystal src/cnf-conformance.cr cnf_setup cnf-path=example-cnfs/linkerd
```

Run the conformance suite: 
```
crystal src/cnf-conformance.cr all
```

linkerd cleanup
```
crystal src/cnf-conformance.cr cnf_cleanup cnf-path=example-cnfs/linkerd
```
  
