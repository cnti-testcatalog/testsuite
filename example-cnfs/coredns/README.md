# What is [CoreDNS](https://coredns.io/)

CoreDNS is a DNS server/forwarder, written in Go, that chains plugins. Each plugin performs a (DNS) function.

DNS is a critical network function that can be found in many Telecom use cases such as the vCPE.

CoreDNS can listen for DNS requests coming in over UDP/TCP, TLS (RFC 7858), also called DoT, DNS over HTTP/2 - DoH - (RFC 8484) and gRPC (not a standard).

# Prerequistes

Follow [Pre-req steps](../../INSTALL.md#pre-requisites), including

- Set the KUBECONFIG environment to point to the remote K8s cluster
- Downloading the binary cnf-testsuite release

### Automated CNF installation

Initialize the test suite

```
./cnf-testsuite setup
```

Configure and deploy CoreDNS as the target CNF

```
./cnf-testsuite cnf_setup cnf-path=example-cnfs/coredns/cnf-testsuite.yml
```

Run the all the tests

```
./cnf-testsuite all
```

Check the results file

Cleanup the cnf test setup (including undeployment of CoreDNS)

```
./cnf-testsuite cnf_cleanup cnf-path=example-cnfs/coredns
```
