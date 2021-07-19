CNF Test Suite Roadmap
---

This document defines a high level roadmap for the CNF Test Suite.

The following is a selection of some of the major features the CNF Test Suite team plans to explore. This roadmap will continue to be updated as priorities evolve. 

To get a more complete overview of planned features and current work see the [project board](https://github.com/cncf/cnf-testsuite/projects/1), [issue tracker](https://github.com/cncf/cnf-testsuite/issues) and [milestones](https://github.com/cncf/cnf-testsuite/milestones) in GitHub.

### Create tests

- Build tests for Kubernetes best practices that address issues voiced by the end users, including:
    - On-boarding (day 1) items
    - CNF WG best practices
- Build [resilience tests](https://github.com/cncf/cnf-testsuite/blob/main/USAGE.md#resilience-tests) using [LitmusChaos](https://litmuschaos.io/) experiments
- Create [observability tests](https://github.com/cncf/cnf-testsuite/blob/main/USAGE.md#observability-tests) to check for cloud native monitoring
- Create [state tests](https://github.com/cncf/cnf-testsuite/blob/main/USAGE.md#state-tests) to check cloud native data handling

### Enhance the functionality of the test suite framework

- Add support for air gapped environments
- Add best practice suggestions to test results
- Split libraries out into different repositories under a single organization

### Onboard maintainers

- Document a Governance structure for maintainers
- Document a Contributor Ladder for maintainer levels
- Publish a "Getting Started with the CNF Test Suite" blog post
- Create "Office Hours" and "good first issues" to help beginners
- Engage CNCF-hosted projects and propose test ideas using their software
- Enlist help from other communities
    - Crystal Lang
    - CNCF Technical Advisory Groups (TAGs) 
    - Kubernetes Special Interest Groups (SIGs)

### Onboard end users

- Create "ADOPTERS.md" file to list users of the CNF Test Suite 
- Set up [Calendly](https://calendly.com/cnftestsuite) to schedule presentations
- Offer presentations, demonstrations and assistance on the CNF Test Suite to Service Providers and CNF Developers
    - To request a presentation, please open an [issue](https://github.com/cncf/cnf-testsuite/issues/new) or schedule via [Calendly](https://calendly.com/cnftestsuite)
- Promote test suite with new groups and communities
    - Present at Network of the Future (NoF) seminar
