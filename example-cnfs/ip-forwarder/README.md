# Set up IP-Forwarder CNF
./example-cnfs/ip-forwarder/readme.md
# Prerequistes
### Install helm version 3

### Automated IP-Forwarder installation
Run cnf-conformance setup 
```
export KUBECONFIG=$(pwd)/<YourKubeConf> ; crystal src/cnf-conformance.cr setup
```
Install IP-Forwarder
```
export KUBECONFIG=$(pwd)/admin.conf ; crystal src/cnf-conformance.cr example_cnf_setup example-cnf-path=example-cnfs/ip-forwarder
```
### Automated IP-Forwarder cleanup
```
export KUBECONFIG=$(pwd)/admin.conf ; crystal src/cnf-conformance.cr example_cnf_cleanup example-cnf-path=example-cnfs/ip-forwarder
```
Run the conformance suite: `export KUBECONFIG=$(pwd)/admin.conf ; crystal src/cnf-conformance.cr all`

### Manual IP-Forwarder installation
1. Install helm version 3
1. Make the cnfs/ip-forwarder diretory 
1. If you are testing the cnf source, clone the source into the cnfs/ip-forwarder directory
1. Copy the cnf-conformance.yml into the cnfs/ip-forwarder directory
1. Install ip-forwarder using helm: `helm install ip-forwarder cnfs/csp`
1. Wait for the installation to finish (all pods are ready)
1. Run the conformance suite: `export KUBECONFIG=$(pwd)/admin.conf ; crystal src/cnf-conformance.cr all`


  
