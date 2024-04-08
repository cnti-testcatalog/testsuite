# CNTI Test Catalog

| Main                                                                                                                                        |
| ------------------------------------------------------------------------------------------------------------------------------------------- |
| [![Build Status](https://github.com/cnti-testcatalog/testsuite/workflows/Crystal%20Specs/badge.svg)](https://github.com/cnti-testcatalog/testsuite/actions) |

The CNTI Test Catalog is a tool that validates telco application's adherence to [cloud native principles](https://networking.cloud-native-principles.org/) and best practices. 

This Test Catalog focus area is one part of LF Networking's [Cloud Native Telecom Initiative (CNTI)](https://wiki.lfnetworking.org/pages/viewpage.action?pageId=113213592) and works closely with the [CNTI Best Practices](https://wiki.lfnetworking.org/display/LN/Best+Practices) and [CNTI Certification](https://wiki.lfnetworking.org/display/LN/Certification) focus areas.

## Installation and Usage

To get the CNTI Test Catalog up and running, see the [Installation Guide](INSTALL.md).

#### To give it a try immediately you can use these quick install steps

Prereqs: kubernetes cluster, wget, curl, helm 3.1.1 or greater on your system already.

1. Install the latest test suite binary: `source <(curl -s https://raw.githubusercontent.com/cnti-testcatalog/testsuite/main/curl_install.sh)`
2. Run `setup` to prepare the cnf-testsuite: `cnf-testsuite setup`
3. Pull down an example CNF configuration to try: `curl -o cnf-testsuite.yml https://raw.githubusercontent.com/cnti-testcatalog/testsuite/main/example-cnfs/coredns/cnf-testsuite.yml`
4. Initialize the test suite for using the CNF: `cnf-testsuite cnf_setup cnf-config=./cnf-testsuite.yml`
5. Run all of application/workload tests: `cnf-testsuite workload`

#### More Usage docs

Check out the [usage documentation](USAGE.md) for more info about invoking commands and logging.

## Cloud Native Categories

The CNTI Test Catalog will inspect CNFs for the following characteristics:

- **Configuration** - The CNF's configuration should be managed in a declarative manner, using ConfigMaps, Operators, or other declarative interfaces.
- **Compatibility, Installability & Upgradability** - CNFs should work with any Certified Kubernetes product and any CNI-compatible network that meet their functionality requirements while using standard, in-band deployment tools such as Helm (version 3) charts.
- **Microservice** - The CNF should be developed and delivered as a microservice.
- **State** - The CNF's state should be stored in a custom resource definition or a separate database (e.g. etcd) rather than requiring local storage. The CNF should also be resilient to node failure.
- **Reliability, Resilience & Availability** - CNFs should be reliable, resilient and available to failures inevitable in cloud environments. CNFs should be tested to ensure they are designed to deal with non-carrier-grade shared cloud HW/SW platforms.
- **Observability & Diagnostics** - CNFs should externalize their internal states in a way that supports metrics, tracing, and logging.
- **Security** - CNF containers should be isolated from one another and the host. CNFs are to be verified against any common CVE or other vulnerabilities.

See the [Complete Test Documentation](docs/TEST_DOCUMENTATION.md) for a complete overview of the tests.

## Contributing

Welcome! We gladly accept contributions on new tests, example CNFs, updates to documentation, enhancements, bug reports, and more.

- [Contributing guide](CONTRIBUTING.md)
- [Good first issues](https://github.com/cnti-testcatalog/testsuite/labels/good%20first%20issue)
- [Contributions welcome](https://github.com/cnti-testcatalog/testsuite/labels/contributions-welcome)

## Communication and community meetings

- Join the conversation on [LFN Tech's Slack](https://lfntech.slack.com/) channels
  - [#cnti-general](https://lfntech.slack.com/archives/C06GV633PRD)
  - [#cnti-bestpractices](https://lfntech.slack.com/archives/C06GV4J8S5U)
  - [#cnti-testcatalog-testsuite](https://lfntech.slack.com/archives/C06GM6ZEPUP)
  - [#cnti-testsuite-dev](https://lfntech.slack.com/archives/C06HQGWK4NL)
  - [#cnti-certification](https://lfntech.slack.com/archives/C06GYRL5ZPX)
- Join the weekly CNTI Test Catalog meeting
  - Meetings every Tuesday at 8:00am - 9:00am Pacific Time 
  - Meeting minutes are [here](https://docs.google.com/document/d/1yjL079TR0L1q__BRuhREeXfx5MtAmjPzbFZlZUeBsK4/edit)

## Past Presentations

**CNTI Test Catalog Demo 2021**
- [Recording](https://drive.google.com/file/d/1SBHE5Dqx6Sa-m83WODbCEbbdiB2_l_U2/view?usp=sharing)
- [Slides](https://github.com/cnti-testcatalog/testsuite/files/6857515/SHARED-COMMON.CNF.Test.Suite.Demo.and.CNF.initiatives.overview.2021-06-29.pdf) (PDF)

**Crystal in the Cloud: A cloud native journey at Crystal 1.0 Conference 2021**
- [Recording](https://youtu.be/n8g60VglyUw)
- [Slides](https://github.com/cnti-testcatalog/testsuite/files/6785788/Crystal.1.0.Crystal.in.the.Cloud_.CNF.Test.Suite.pdf) (PDF)


## Implementation overview

The CNTI Test Catalog leverages upstream tools such as [OPA Gatekeeper](https://github.com/open-policy-agent/gatekeeper), [Helm linter](https://github.com/helm/chart-testing), and [Promtool](https://prometheus.io/docs/prometheus/latest/configuration/unit_testing_rules/) for testing CNFs. The upstream tool installation, configuration, and versioning has been made repeatable.

The test framework and tests (using the upstream tools) are written in the human-readable, compiled language, [Crystal](https://crystal-lang.org/). Common capabilities like dependencies between tests and categories are supported.

Setup of vanilla upstream K8s on [Equinix Metal](https://metal.equinix.com/) is done with the [CNF Testbed](https://github.com/cncf/cnf-testbed/) platform tool chain, which includes [k8s-infra](https://github.com/crosscloudci/k8s-infra), [Kubespray](https://kubespray.io/). To add support for other providers, please submit a [Pull Request](https://github.com/cncf/cnf-testbed/pulls) to the [CNF Testbed](https://github.com/cncf/cnf-testbed/) repo.

## Code of Conduct

The CNTI Test Catalog community follows the [CNCF Code of Conduct](https://github.com/cncf/foundation/blob/main/code-of-conduct.md).

## License terms

The CNTI Test Catalog is available under the [Apache 2 license](LICENSE.md).
