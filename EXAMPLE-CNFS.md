### EXAMPLE-CNFs (DRAFT)

This is a preliminary list of CNF samples for each layer in the [OSI model](https://www.osi-model.com/presentation-layer/) which we plan to test in the CNF Conformance Test Suite

**Goals:**

- Find a CNF which can be used as a sample in the CNF Conformance suite for testing on each OSI layer. 
     - Ideally it will be a different CNF for each layer, but this is not a hard requirement.
- Provide a summary of the CNFs for each layer
- Provide a description of what each CNF is and what it does for each layer.


## [Layer 7 - Application](https://en.wikipedia.org/wiki/Application_layer)

- [CoreDNS sample](https://github.com/cncf/cnf-conformance/tree/master/sample-cnfs/sample-coredns-cnf)
- [NFF Go Deep Packet Inspection example](https://github.com/intel-go/nff-go/tree/master/examples/dpi) example


## [Layer 6 - Presentation](https://en.wikipedia.org/wiki/Presentation_layer) ([osi-model](https://www.osi-model.com/presentation-layer/))
- [linkerd](https://github.com/linkerd/linkerd) - https://github.com/cncf/cnf-conformance/issues/112 (TLS)
- [NFF Go Deep Packet Inspection example](https://github.com/intel-go/nff-go/tree/master/examples/dpi) example


## [Layer 5 - Session](https://en.wikipedia.org/wiki/Session_layer)

- [linkerd](https://github.com/linkerd/linkerd) - https://github.com/cncf/cnf-conformance/issues/112
    - Built on [Finagle](https://twitter.github.io/finagle/) 
        - _Finagle operates at Layer 5 in the OSI model (the “session” layer)_ ([ref](https://linkerd.io/2016/03/16/beyond-round-robin-load-balancing-for-latency/))
- [Rsocket](https://github.com/rsocket/rsocket-go) A [layer 5/6](https://medium.com/netifi/differences-between-grpc-and-rsocket-e736c954e60) binary protocol


## [Layer 4 - Transport](https://en.wikipedia.org/wiki/Transport_layer)

- [NFF Go Anti DDOS example](https://github.com/intel-go/nff-go/tree/master/examples/antiddos)
- [NFF Go NAT example](https://github.com/intel-go/nff-go-nat)
- [Envoy](https://www.envoyproxy.io/) (L3+L4)
- [linkerd](https://github.com/linkerd/linkerd) - https://github.com/cncf/cnf-conformance/issues/112
    - [Linkerd proxy-Automatic layer-4 load balancing for non-HTTP traffic](https://linkerd.io/2/reference/architecture/#proxy)
- [Tungsten Fabric](https://tungsten.io/)


## [Layer 3 - Network](https://en.wikipedia.org/wiki/Network_layer)

- [NFF Go IP Forwarding example](https://github.com/intel-go/nff-go/tree/master/examples/forwarding)
- [NFF Go IPsec example](https://github.com/intel-go/nff-go/tree/master/examples/ipsec)
- [CNF Testbed IPsec example](https://github.com/cncf/cnf-testbed/tree/master/examples/use_case/ipsec)
- [NFF Go NAT example](https://github.com/intel-go/nff-go-nat)
- [Envoy](https://www.envoyproxy.io/) (L3+L4)
- [Flannel configures a layer 3 IPv4 overlay network](https://rancher.com/blog/2019/2019-03-21-comparing-kubernetes-cni-providers-flannel-calico-canal-and-weave/)
- [FRRouting](https://frrouting.org/) ([github repo](https://github.com/FRRouting/frr))
- [Tungsten Fabric](https://tungsten.io/)
- [OpenSwitch NAS Layer 3](https://github.com/open-switch/opx-nas-l3)
- CNI K8s add-ons operating on Layer 3 such as the Calico kube-policy-controller container


## [Layer 2 - Data](https://en.wikipedia.org/wiki/Data_link_layer)
[VPP Layer 2 Vlans](https://wiki.fd.io/view/VPP/Per-feature_Notes#VLAN_And_Tags)

- VPP Bridge
- Linux vNics
- [NFF Go NAT example](https://github.com/intel-go/nff-go-nat)
    * MAC address for "internal" machine
- PDN GW
- Serving GW
- [OvS](http://www.openvswitch.org/) 
- Something from [O-RAN](https://o-ran-sc.org/) ([wiki](https://wiki.o-ran-sc.org/display/ORAN), [repos](https://gerrit.o-ran-sc.org/r/admin/repos))
- OMEC component
- [FRRouting](https://frrouting.org/) ([github repo](https://github.com/FRRouting/frr))
- [Tungsten Fabric](https://tungsten.io/)
- [OpenSwitch NAS Layer 2](https://github.com/open-switch/opx-nas-l2)
