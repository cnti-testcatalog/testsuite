# cnf_conformance
The CNF Conformance program enables interoperability of CNFs from multiple vendors running on top of Kubernetes supplied by different vendors. The goal is to provide an open source test suite to enable both open and closed source CNFs to demonstrate conformance and implementation of best practices.

## Installation
  * Install [crystal-lang](https://crystal-lang.org/install/) version 0.30.1
  * First clone this cnf-conformance repository 
  * `cd cnf-conformance`
  * Next clone the CNF-Testbed 
  * `cd cnfs/ && git clone https://github.com/cncf/cnf-testbed.git`
  * Then clone the K8s-infra repo 
  * `cd tools/ && git clone https://github.com/crosscloudci/k8s-infra.git`
  * Follow the K8s-infra README.md for instructions on how to install
  * ### Get ready to rock and roll! 

## Example Usage
  * `crystal src/tasks/declarative/ip_address.cr install_script_helm`

## Development
  The cnf-conformance test suite is modeled after make, or if you're famniliar with Ruby, rake. Conformance tests are created via tasks using the Crystal library SAM.cr. 

## Contributing

1. Fork it (<https://github.com/your-github-user/cnf_conformance/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

  - [W. Watson](https://github.com/wavell) - creator and maintainer
  - [Joshua Darius](https://github.com/nupejosh) - creator and maintainer
