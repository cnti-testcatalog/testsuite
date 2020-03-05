# CNF Conformance
Develop: [![Build Status](https://www.travis-ci.org/vulk/cnf-conformance.svg?branch=develop)](https://www.travis-ci.org/vulk/cnf-conformance)
Master: [![Build Status](https://www.travis-ci.org/vulk/cnf-conformance.svg?branch=master)](https://www.travis-ci.org/vulk/cnf-conformance)

The CNF Conformance program enables interoperability of Cloud native Network Functions (CNFs) from multiple vendors running on top of Kubernetes supplied by different vendors. The goal is to provide an open source test suite to demonstrate conformance and implementation of best practices for both open and closed source Cloud native Network Functions. 

The CNF Conformance Test Suite will inspect CNFs for the following characteristics: 
- **Compatibility** - CNFs should work with any Certified Kubernetes product and any CNI-compatible network that meet their functionality requirements.
- **Statelessness** - The CNF's state should be stored in a custom resource definition or a separate database (e.g. etcd) rather than requiring local storage. The CNF should also be resilient to node failure.
- **Security** - CNF containers should be isolated from one another and the host.
- **Scalability** - CNFs should support horizontal scaling (across multiple machines) and vertical scaling (between sizes of machines).
- **Configuration and Lifecycle** - The CNF's configuration and lifecycle should be managed in a declarative manner, using ConfigMaps, Operators, or other declarative interfaces.  
- **Observability** - CNFs should externalize their internal states in a way that supports metrics, tracing, and logging.
- **Installable and Upgradeable** - CNFs should use standard, in-band deployment tools such as Helm (version 3) charts.
- **Hardware Resources and Scheduling** - The CNF container should access all hardware and schedule to specific worker nodes by using a device plugin.

See the [Conformance Test Categories Documentation](https://github.com/cncf/cnf-conformance/blob/master/TEST-CATEGORIES.md) for a complete overview of the tests.

## Implementation overview

The CNF Conformance Test Suite leverages upstream tools such as [OPA Gatekeeper](https://github.com/open-policy-agent/gatekeeper), [Helm linter](https://github.com/helm/chart-testing), and [Promtool](https://prometheus.io/docs/prometheus/latest/configuration/unit_testing_rules/) for testing CNFs. The upstream tool installation, configuration and versioning has been made repeatable.

The test framework and tests (using the upstream tools) are written in the human readable, compiled language, [Crystal](https://crystal-lang.org/). Common capabilities like dependencies between tests and categories are supported.

Setup of vanilla upstream K8s on [Packet](https://www.packet.com/) is done with the [CNF Testbed](https://github.com/cncf/cnf-testbed/) platform tool chain, which includes [k8s-infra](https://github.com/crosscloudci/k8s-infra), [Kubespray](https://kubespray.io/). To add support for other providers, please submit a [Pull Request](https://github.com/cncf/cnf-testbed/pulls) to the [CNF Testbed](https://github.com/cncf/cnf-testbed/) repo.


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

## Contributing

1. Fork it (<https://github.com/your-github-user/cnf-conformance/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Maintainers

  - [W. Watson](https://github.com/wavell) - creator and maintainer
  - [Joshua Darius](https://github.com/nupejosh) - creator and maintainer
  - [Denver Williams](https://github.com/denverwilliams) - creator and maintainer
  - [William Harris](https://github.com/williscool) - creator and maintainer
  - [Taylor Carpenter](https://github.com/taylor) - creator and maintainer
  - [Lucina Stricko](https://github.com/lixuna) - maintainer
