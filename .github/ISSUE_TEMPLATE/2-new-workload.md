---
name: New Workload Test
about: Creating a new workload testsuite test
title: "[Workload]"
labels: workload
assignees: ""
---

## Title: [Workload] CATEGORY_NAME test: DESCRIPTIVE_TEST_NAME

**Is your workload test idea related to a problem? Please describe.**
- tbd

**Describe the solution you'd like**
- tbd

**Test Category Name**
- ADD CATEGORY_NAME (e.g. State, Security, etc from [README](https://github.com/cncf/cnf-testsuite/blob/main/README.md#cnf-testsuite))

**Type of test (static or runtime)**
- tbd

---

### Documentation tasks:
- [ ] Update [installation instructions](https://github.com/cncf/cnf-testsuite/blob/main/install.md) if needed
- [ ] Update [Test Categories md](https://github.com/cncf/cnf-testsuite/blob/main/TEST-CATEGORIES.md) if needed
- [ ] Update [USAGE md](https://github.com/cncf/cnf-testsuite/blob/main/USAGE.md) if needed
      - [ ] how to run
      - [ ] Description and details
           - [ ] what the best practice is
           - [ ] why are we testing this
       - [ ] Remediation steps if test does not pass

### QA tasks

Dev Review:

- [ ] walk through A/C
- [ ] do you get the expected result?
- [ ] if yes,
  - [ ] move to `Needs Peer Review` column
  - [ ] create Pull Request and follow check list
  - [ ] Assign 1 or more people for peer review
- [ ] if no, document what additional tasks will be needed

Peer review:

- [ ] walk through A/C
- [ ] do you get the expected result?
- [ ] if yes,
  - [ ] move to `Reviewer Approved` column
  - [ ] Approve pull request
- [ ] if no,
  - [ ] document what did not go as expected, including error messages and screenshots (if possible)
  - [ ] Add comment to pull request
  - [ ] request changes to pull request
