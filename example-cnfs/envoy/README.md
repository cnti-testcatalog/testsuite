# Set up Envoy CNF
./example-cnfs/envoy/readme.md
# Prerequistes
### Install helm version 3

### Automated Envoy installation
Run cnf-conformance setup 
```
export KUBECONFIG=$(pwd)/<YourKubeConf> ; crystal src/cnf-conformance.cr setup
```
Install Envoy
```
export KUBECONFIG=$(pwd)/admin.conf ; crystal src/cnf-conformance.cr example_cnf_setup example-cnf-path=example-cnfs/envoy
```
### Automated Envoy cleanup
```
export KUBECONFIG=$(pwd)/admin.conf ; crystal src/cnf-conformance.cr example_cnf_cleanup example-cnf-path=example-cnfs/envoy
```
Run the conformance suite: `export KUBECONFIG=$(pwd)/admin.conf ; crystal src/cnf-conformance.cr all`

### Manual Envoy installation
1. Install helm version 3
1. Make the cnfs/envoy diretory 
1. If you are testing the cnf source, clone the source into the cnfs/envoy directory
1. Copy the cnf-conformance.yml into the cnfs/envoy directory
1. Install envoy using helm: `helm install envoy stable/envoy`
1. Make the cnfs/envoy/helm_chart directory
1. Retrieve the helm chart source: `helm pull stable/envoy`
1. Move the tar file into the cnfs/envoy/helm_chart directory
1. Untar the tar file
1. Move the contents of the new helm chart source directory into the cnfs/envoy/helm_chart directory (up one level)
1. Wait for the installation to finish (all pods are ready)
1. Run the conformance suite: `export KUBECONFIG=$(pwd)/admin.conf ; crystal src/cnf-conformance.cr all`


  
