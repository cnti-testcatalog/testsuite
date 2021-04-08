# What is [CoreDNS](https://coredns.io/)

CoreDNS is a DNS server/forwarder, written in Go, that chains plugins. Each plugin performs a (DNS) function.

DNS is a critical network function that can be found in many Telecom use cases such as the vCPE.

CoreDNS can listen for DNS requests coming in over UDP/TCP, TLS (RFC 7858), also called DoT, DNS over HTTP/2 - DoH - (RFC 8484) and gRPC (not a standard).


# Prerequistes
Follow [Pre-req steps](https://github.com/cncf/cnf-conformance/blob/main/INSTALL.md#prerequisites), including
- Set the KUBECONFIG environment to point to the remote K8s cluster
- Downloading the binary cnf-conformance release

### Automated CNF installation

Initialize the conformance suite
```
crystal src/cnf-conformance.cr setup
```

Configure and deploy CoreDNS as the target CNF
```
crystal src/cnf-conformance.cr cnf_setup cnf-path=example-cnfs/coredns
```

Run the all the tests
```
crystal src/cnf-conformance.cr all
```

Check the results file

Cleanup the cnf test setup (including undeployment of CoreDNS)
```
crystal src/cnf-conformance.cr cnf_cleanup cnf-path=example-cnfs/coredns
```
