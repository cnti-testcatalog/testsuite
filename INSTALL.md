Installing the CNF Conformance Test Suite
---

This guide shows how to install the CNF Conformance Test Suite


# Source Install

## Installation
  * Install [crystal-lang](https://crystal-lang.org/install/) version 0.30.1
  * Install the project's crystal dependencies
  ```
  shards install
  ```
  * #### First clone this cnf-conformance repository 
  ```
  cd cnf-conformance
  ```
  * #### Next clone the CNF-Testbed 
  ```
  cd cnfs/ && git clone https://github.com/cncf/cnf-testbed.git
  ```
  * #### (Optional: Create a K8s cluster if you don't already have one)

  * follow the [kind install](KIND-INSTALL.md) instructions to setup a cluster in kind


  * Clone the K8s-infra repo then Follow the [prerequisites](https://github.com/cncf/cnf-testbed/tree/master/tools#pre-requisites) for [deploying a K8s cluster](https://github.com/cncf/cnf-testbed/tree/master/tools#deploying-a-kubernetes-cluster-using-the-makefile--ci-tools)  for a Packet host. 

  *Or* 
  * If you already have IP addresses for your provider, and you want to manually install a K8s cluster, you can use k8s-infra to do this.
  ```
  cd tools/ && git clone https://github.com/crosscloudci/k8s-infra.git
  ```
  * #### Follow the [K8s-infra quick start](https://github.com/crosscloudci/k8s-infra/blob/master/README.md#quick-start) for instructions on how to install

  * Make sure you set your KUBECONFIG
  ```
  export KUBECONFIG=<yourkubeconfig>
  ```
  * Modify the cnf-conformance.yml file settings for your cnfs in your cnf's base directory 
  ```
  # In ./cnfs/YOURCNFDIRECTORY/cnf-conformance.yml
  
helm_directory: 
install_script: 
deployment_name: 
helm_chart: 
helm_chart_container_name: 
white_list_helm_chart_container_names: 
  ```

  * Run the setup tasks to install any prerequisites (useful for setting up sample cnfs)
  ``` 
  crystal src/cnf-conformance.cr setup
  ```
  * Run the cleanup tasks to remove prerequisites (useful for starting fresh)
  ``` 
  crystal src/cnf-conformance.cr cleanup
  ```
  * To set up a *sample cnf* for use with cnf-conformance
  ``` 
  crystal src/cnf-conformance.cr sample_coredns_setup
  ```
  ### Get ready to rock and roll! 

## Example Usage (or see the [complete usage documentation](https://github.com/cncf/cnf-conformance/blob/master/USAGE.md))
  ```
  # Run all ga tests (generally available tests)
  crystal src/cnf-conformance.cr all 
  
  # Run all beta and ga tests
  crystal src/cnf-conformance.cr all beta
  
  # Run all alpha, beta, and ga tests
  crystal src/cnf-conformance.cr all alpha
  
  # Run all wip, alpha, beta, and ga tests
  crystal src/cnf-conformance.cr all wip
  
  # Run all tests in the configureation lifecycle category
  crystal src/cnf-conformance.cr configuration_lifecycle 
  
  # Run all tests in the installability
  crystal src/cnf-conformance.cr installability 
  ```

## Development
  The CNF Conformance Test Suite is modeled after make, or if you're familiar with Ruby, [rake](https://github.com/ruby/rake). Conformance tests are created via tasks using the Crystal library, [SAM.cr](https://github.com/imdrasil/sam.cr). 

  To run the automated test suite:
  ``` 
  crystal spec
  ```

# CNF Creator/Vendor Install and Usage guide

## Prerequisites

- [Kubectl binary is installed](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [Access](https://kubernetes.io/docs/tasks/access-application-cluster/access-cluster/) to a working [Certified K8s](https://cncf.io/ck) cluster via [KUBECONFIG environment variable](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/#set-the-kubeconfig-environment-variable). (See [K8s Getting started guide](https://kubernetes.io/docs/setup/) for options)
    - `export KUBECONFIG=$HOME/mycluster.config`
    - Running `kubectl cluster-info` should show a running Kubernetes master in the output
- Deploy CNF to cluster.  Eg. `helm install coredns stable/coredns`
    - _Note: Not automated at this time_



## Setup and configuration


**Download/Install the conformance suite**

- Download the latest [binary release](https://github.com/cncf/cnf-conformance/releases)
- Make the binary executable (eg. `chmod +x cnf-conformance`)
- Move the downloaded binary to somewhere in your executable PATH (eg. `sudo cp cnf-conformance /usr/local/bin/cnf-conformance`)



_Alternative: [source install](https://github.com/cncf/cnf-conformance/blob/master/INSTALL.md#source-install)_



**Configure the conformance suite for testing a CNF**
- Initialize the test suite by running `cnf-conformance setup` (creates cnfs folder and other items)
- Create a folder under the `cnfs/` directory for your CNF. Eg. `cnfs/my_layer4_proxy_cnf` or `cnfs/my_ipsec_cnf`
- Create a Conformance configuration file called `cnf-confromance.yml` under the your CNF folder (eg. `cnfs/my_ipsec_cnf/cnf-conformance.yml`)
  - Example config (See [latest example in repo](https://github.com/cncf/cnf-conformance/blob/master/cnf-conformance-example.yml)): 
```   
---
# Local copy of CNFs Helm chart
helm_directory: cnfs/coredns/helm_chart/coredns
# Publishd Helm chart name for CNF
helm_chart: stable/coredns
# Container name in deployment pod spec
helm_chart_container_name: coredns
git_clone_url: 
install_script: coredns/Makefile
release_name: coredns
deployment_name: coredns-coredns 
application_deployment_names: [coredns-coredns]
cnf_image_version: latest
white_list_helm_chart_container_names: [falco, nginx, coredns, calico-node, kube-proxy, nginx-proxy]
```
  - Optionally, copy the example configuration file, `cnf-conformance-example.yml`, and modify appropriately
  

## Running and checking results for the Conformance testing


**Running the suite**

```
cnf-conformance all
```

**Checking the results**

In the console where the test suite runs:
- PASSED or FAILED will be displayed for the tests

A test log file, eg. `cnf-conformance-results-20200401.txt`, will be created which lists PASS or FAIL for every test
