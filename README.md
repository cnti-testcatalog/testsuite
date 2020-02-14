# cnf-conformance
The CNF Conformance program enables interoperability of CNFs from multiple vendors running on top of Kubernetes supplied by different vendors. The goal is to provide an open source test suite to enable both open and closed source CNFs to demonstrate conformance and implementation of best practices.  See the [Conformance Test Categories documentation](https://github.com/cncf/cnf-conformance/blob/master/TEST-CATEGORIES.md) for a complete overview of the tests.

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
  * #### Then clone the K8s-infra repo 
  ```
  cd tools/ && git clone https://github.com/crosscloudci/k8s-infra.git
  ```
  * #### Follow the K8s-infra README.md for instructions on how to install
  ### Get ready to rock and roll! 

## Example Usage
  ```
  crystal src/cnf-conformance.cr all 
  crystal src/cnf-conformance.cr configuration_lifecycle 
  crystal src/cnf-conformance.cr installability 
  ```

## Development
  The cnf-conformance test suite is modeled after make, or if you're famniliar with Ruby, rake. Conformance tests are created via tasks using the Crystal library SAM.cr. 

## Contributing

1. Fork it (<https://github.com/your-github-user/cnf-conformance/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

  - [W. Watson](https://github.com/wavell) - creator and maintainer
  - [Joshua Darius](https://github.com/nupejosh) - creator and maintainer
  - [Denver Williams](https://github.com/denverwilliams) - creator and maintainer
  - [William Harris](https://github.com/williscool) - creator and maintainer
