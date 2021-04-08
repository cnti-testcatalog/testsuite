CNF Conformance Test Suite Frequently Asked Questions 
---

### General
<details> <summary>What is CNF Conformance?</summary>
<p>

 - The CNF Conformance program enables interoperability of Cloud native Network Functions (CNFs) from multiple vendors running on top of Kubernetes. The goal is to provide an open source test suite to demonstrate conformance and implementation of best practices for both open and closed source Cloud native Network Functions.

</p>
</details>

<details> <summary>Can I contribute to the CNF Conformance Project?</summary>
<p>

 - Yes. You can start by reading the [CNF Conformance Contributing Guidelines](https://github.com/cncf/cnf-conformance/blob/main/CONTRIBUTING.md).

</p>
</details>

<details> <summary>Does the CNF Conformance community meet?</summary>
<p>

 - Yes. The CNF Conformance team meets once a week on Thursdays at 14:15-15:00 UTC. You can find more info about the meeting [here.](https://github.com/cncf/cnf-conformance/blob/main/CONTRIBUTING.md#community-meeting)

</p>
</details>

<details> <summary>Does CNF Conformance have a slack channel?</summary>
<p>

 - Yes. We have several two channels on [https://slack.cncf.io/](https://slack.cncf.io/), cnf-conformance and cnf-conformance-dev.

</p>
</details>

<details> <summary>What platforms are supported by CNF Conformance?</summary>
<p>

 - CNF Conformance runs on most major Linux distributions and WSL (Windows Subsystem for Linux). 

</p>
</details>

<details> <summary>If I found a bug or I think it's a bug, how do I report it?</summary>
<p>

 - If you would like to report a bug, please create a [new issue](https://github.com/cncf/cnf-conformance/issues/new?assignees=&labels=bug&template=bug-report.md&title=%5BBUG%5D) (using the **Bug Report** Template).

</p>
</details>

<details> <summary>How do I request a new feature?</summary>
<p>

 - If you would like to request an enhancement, please create a [new issue](https://github.com/cncf/cnf-conformance/issues/new?assignees=&labels=enhancement&template=feature-request.md&title=%5BFeature%5D) (using the **Feature Request** Template).

</p>
</details>

<details> <summary>Can I request a new workload or platform test for CNF Conformance?</summary>
<p>

 - Yes. If you would like to request a new workload test, please create a [new issue](https://github.com/cncf/cnf-conformance/issues/new?assignees=&labels=workload&template=new-workload-test.md&title=%5BWorkload%5D) (using the **New Workload Test** Template) or create a [new issue](https://github.com/cncf/cnf-conformance/issues/new?assignees=&labels=platform&template=new-platform-test.md&title=%5BPlatform%5D) (using the **New Platform Test** Template).

</p>
</details>

### Technical and Usage
<details> <summary>Can I run CNF Conformance without a Kubernetes cluster?</summary>
<p>

 - In simple terms, no. You need some type of Kubernetes (K8s) cluster whether it's bare metal, kind, Docker and so on to run CNF Conformance suite against your CNF.

</p>
</details>

<details> <summary>Does CNF Conformance have any pre-requisites or other requirements to run?</summary>
<p>

 - Yes. There are a few requirements for CNF Conformance. You can read about the requirements in the [INSTALL Guide](https://github.com/cncf/cnf-conformance/blob/main/INSTALL.md#prerequisites).

</p>
</details>

<details> <summary>How are points assigned for tests?</summary>
<p>

 - Points are different for each test and workload but in general terms, pass defaults to 5 and fail is a -1. See [points.yml](https://github.com/cncf/cnf-conformance/blob/main/points.yml) for more details on the different points for default scoring.

</p>
</details>

<details> <summary>Does CNF Conformance support or run on other architectures besides amd64?</summary>
<p>

 - Not currently at this time.

</p>
</details>

<details> <summary>Can I run CNF Conformance on clusters currently in use?</summary>
<p>

 - Yes but it's not recommended. There is a destructive option that will test your nodes with reboots and recovery. We recommend that tests are run in an environment that is not currently used by others, typically in a test or dev environment setting.

</p>
</details>

<details> <summary>I ran several tests and missed the output of the results, are these lost or can I view past test results?</summary>
<p>

 - All test results are stored in the results/ directory of where you installed the CNF Conformance suite in yaml format.

</p>
</details>

<details> <summary>Why is CNF Conformance written in crystal and not in other languages like Go?</summary>
<p>

 - The short answer is Crystal fit the criteria we looked at in a language at the time which needed to run external programs/test suites and internal tests - [Taylor Carpenter](https://app.slack.com/client/T08PSQ7BQ/G019HM3K54H/user_profile/U7HCKCW90) via https://slack.cncf.io/ 
 - Usability for Humans - Crystal, puts readablility for humans as a priority, which is why its syntax heavily inspired by Ruby.
 - Type checking system to help humans catch their errors earlier
 - Compiled language for portability, reduced size, and performance
 - Metaprogramming through Crystal's powerful macro system
 - Concurrency throughy green threads, called fiberes, which communicate over channels like Go lang and Clojure
 - Dependency management for libraries and applications via the [crystal manager Shards](https://github.com/crystal-lang/shards)

</p>
</details>


### Troubleshooting
<details> <summary>Running cnf-conformance says "No found config" or similiar type errors?</summary>
<p>

 - This may indicate that you are not pointing to a valid cnf-conformance.yml config file for your CNF. You may want to read or review the [CNF Conformance INSTALL](https://github.com/cncf/cnf-conformance/blob/main/INSTALL.md) instructions or the [USAGE Documentation](https://github.com/cncf/cnf-conformance/blob/main/USAGE.md). 

</p>
</details>
