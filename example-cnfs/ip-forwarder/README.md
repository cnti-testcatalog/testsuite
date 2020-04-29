# VPP IP Forwarder (from the CNF Testbed)

Upstream: https://github.com/cncf/cnf-testbed/tree/master/examples/network_functions/vpp-ip-forwarder

Description: Basic VPP container attached to host bridge through Multus

Description:
- Based on the fd.io VPP project
- Interface attached to host bridge

### Requirements

To run this example CNF, note the following requirements:
- [Multus](https://github.com/intel/multus-cni) must be installed and available in the cluster. This is available by default if using the [CNF Testbed](https://github.com/cncf/cnf-testbed)
- The example CNF should be installed on a bare-metal K8s cluster. The VPP core assignments have not yet been tested with a Kind cluster, and might cause the example deployment to fail.

# Prerequistes
### Install helm version 3

### Automated installation
Run cnf-conformance setup 
```
export KUBECONFIG=$(pwd)/<YourKubeConf> ; crystal src/cnf-conformance.cr setup
```

Setup and deploy  service chain
```
export KUBECONFIG=$(pwd)/admin.conf ; crystal src/cnf-conformance.cr cnf_setup cnf-path=example-cnfs/ip-forwarder deploy_with_chart=false
```

### Testing
Run the conformance suite: `export KUBECONFIG=$(pwd)/admin.conf ; crystal src/cnf-conformance.cr all`

### Automated cleanup
```
export KUBECONFIG=$(pwd)/admin.conf ; crystal src/cnf-conformance.cr cnf_cleanup cnf-path=example-cnfs/ip-forwarder
```

### Manual installation
1. Install helm version 3
1. Make the cnfs/ip-forwarder diretory 
1. If you are testing the cnf source, clone the source into the cnfs/ip-forwarder directory
1. Copy the cnf-conformance.yml into the cnfs/ip-forwarder directory
1. Deploy the CNF using helm: `helm install cnfs/ip-forwarder/vpp`
1. Wait for the installation to finish (all pods are ready)
1. Run the conformance suite: `export KUBECONFIG=$(pwd)/admin.conf ; crystal src/cnf-conformance.cr all`


  
