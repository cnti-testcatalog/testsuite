# CNF Conformance Test Suite
| Main |
|---|
|[![Build Status](https://github.com/cncf/cnf-conformance/workflows/Crystal%20Specs/badge.svg)](https://github.com/cncf/cnf-conformance/actions)|

The CNF Conformance test suite is a tool that makes it possible to validate telco applications, aka Cloud native Network Functions (CNFs), and the underlying Telecom platforms adherence to Cloud native principles and best practices.

This test suite initiative works closely with the [CNF WG](cnf-wg/README.md) which determines requirements for the CNF Conformance program.

The CNF Conformance Test Suite will inspect CNFs for the following characteristics: 
- **Compatibility** - CNFs should work with any Certified Kubernetes product and any CNI-compatible network that meet their functionality requirements.
- **Statelessness** - The CNF's state should be stored in a custom resource definition or a separate database (e.g. etcd) rather than requiring local storage. The CNF should also be resilient to node failure.
- **Security** - CNF containers should be isolated from one another and the host.
- **Microservice** - The CNF should be developed and delivered as a microservice.
- **Scalability** - CNFs should support horizontal scaling (across multiple machines) and vertical scaling (between sizes of machines).
- **Configuration and Lifecycle** - The CNF's configuration and lifecycle should be managed in a declarative manner, using ConfigMaps, Operators, or other declarative interfaces.  
- **Observability** - CNFs should externalize their internal states in a way that supports metrics, tracing, and logging.
- **Installable and Upgradeable** - CNFs should use standard, in-band deployment tools such as Helm (version 3) charts.
- **Hardware Resources and Scheduling** - The CNF container should access all hardware and schedule to specific worker nodes by using a device plugin.
- **Resilience** - CNFs should be resilient to failures inevitable in cloud environments. CNF Resilience should be tested to ensure CNFs are designed to deal with non-carrier-grade shared cloud HW/SW platforms.

See the [Conformance Test Categories Documentation](https://github.com/cncf/cnf-conformance/blob/main/TEST-CATEGORIES.md) for a complete overview of the tests.

## Contributing

Welcome! We gladly accept contributions on new conformance tests, example CNFs, updates to documentation, enhancements, bug reports, and more.
- [Contributing guide](https://github.com/cncf/cnf-conformance/blob/main/CONTRIBUTING.md)
- [Good first issues](https://github.com/cncf/cnf-conformance/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22)

## Communication and community meetings

- Join the conversation on [CNCF's Slack](https://slack.cncf.io/) channels
    - [#cnf-conformance](https://cloud-native.slack.com/archives/CV69TQW7Q)  
    - [#cnf-conformance-dev](https://cloud-native.slack.com/archives/C014TNCEX8R)
    
- Join the monthly [Telecom User Group meetings](https://github.com/cncf/telecom-user-group#meeting-time) 
    - Meetings on the 1st Mondays of the month 
    - Meeting minutes are [here](https://docs.google.com/document/d/1yhtI7aiwpdAiRBKyUX6mOJDHAbjOog2mI4Ur2k27D7s/edit) 
    
- Join the weekly developer meetings 
    - Meetings every Thursday at 14:15 - 15:00 UTC
    - Meeting minutes are [here](https://docs.google.com/document/d/1IbrgjqIkOCvrrSG0DRE6X62UUZpBq-818Mn8q0nkkd0/edit)

## Implementation overview

The CNF Conformance Test Suite leverages upstream tools such as [OPA Gatekeeper](https://github.com/open-policy-agent/gatekeeper), [Helm linter](https://github.com/helm/chart-testing), and [Promtool](https://prometheus.io/docs/prometheus/latest/configuration/unit_testing_rules/) for testing CNFs. The upstream tool installation, configuration, and versioning has been made repeatable.

The test framework and tests (using the upstream tools) are written in the human-readable, compiled language, [Crystal](https://crystal-lang.org/). Common capabilities like dependencies between tests and categories are supported.

Setup of vanilla upstream K8s on [Equinix Metal](https://metal.equinix.com/) is done with the [CNF Testbed](https://github.com/cncf/cnf-testbed/) platform tool chain, which includes [k8s-infra](https://github.com/crosscloudci/k8s-infra), [Kubespray](https://kubespray.io/). To add support for other providers, please submit a [Pull Request](https://github.com/cncf/cnf-testbed/pulls) to the [CNF Testbed](https://github.com/cncf/cnf-testbed/) repo.


## Installation
To get the CNF Test Suite up and running, see the [Installation Guide](INSTALL.md). 

#### To give it a try immediately you can use these quick install steps
Prereqs: kubernetes cluster, wget, curl, helm 3.1.1 or greater on your system already.

1. Install the latest test suite binary:  `source <(curl https://raw.githubusercontent.com/cncf/cnf-conformance/main/curl_install.sh)`
2. Run `setup` to prepare the cnf-conformance suite: `cnf-conformance setup`
3. Pull down an example CNF configuration to try: `wget -O cnf-conformance.yml https://raw.githubusercontent.com/cncf/cnf-conformance/main/example-cnfs/coredns/cnf-conformance.yml`
4. Initialize the test suite for using the CNF: `cnf-conformance cnf_setup cnf-config=./cnf-conformance.yml`
5. Run all of application/workload tests: `cnf-conformance workload`


## Usage

Check out the [usage documentation](https://github.com/cncf/cnf-conformance/blob/main/USAGE.md) for more info about invoking commands and logging.

## Code of Conduct

The CNF Conformance community follows the [CNCF Code of Conduct](https://github.com/cncf/foundation/blob/main/code-of-conduct.md).

## License terms

CNF Conformance Test Suite is available under the [Apache 2 license](https://github.com/cncf/cnf-conformance/blob/main/LICENSE).
