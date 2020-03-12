Installing the CNF Conformance Test Suite
---

This guide shows how to install the CNF Conformance Test Suite


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
  * #### (Optional: Create a K8s cluster if you don't already have one) Clone the K8s-infra repo 

  * Follow the [prerequisites](https://github.com/cncf/cnf-testbed/tree/master/tools#pre-requisites) for [deploying a K8s cluster](https://github.com/cncf/cnf-testbed/tree/master/tools#deploying-a-kubernetes-cluster-using-the-makefile--ci-tools)  for a Packet host. 
  
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
  crystal src/cnf-conformance.cr all 
  crystal src/cnf-conformance.cr configuration_lifecycle 
  crystal src/cnf-conformance.cr installability 
  ```

## Development
  The CNF Conformance Test Suite is modeled after make, or if you're familiar with Ruby, [rake](https://github.com/ruby/rake). Conformance tests are created via tasks using the Crystal library, [SAM.cr](https://github.com/imdrasil/sam.cr). 
  
  To run the automated test suite:
  ``` 
  crystal spec
  ```
