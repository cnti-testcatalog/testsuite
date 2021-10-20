---
name: New Workload Test
about: Creating a new workload testsuite test
title: "[Workload]"
labels: workload
assignees: ""
---

## [Acceptance Criteria] (TBD)

### CATEGORY_NAME test: DESCRIPTIVE_TEST_NAME

**Short description of workload test:**

- goal of this test

**Test Category**

- ADD CATEGORY_NAME (e.g. State, Security, etc from [README](https://github.com/cncf/cnf-testsuite/blob/main/README.md#cnf-testsuite))

**Type of test (static or runtime)**

- ADD STATIC or RUNTIME

**Proof of Concept** (if available)

- [ ] link to proof of concept of new workload test

---

### Implementation Tasks: TBD

**Environment set up tasks:**

- [ ]

**Upstream tool set up tasks: (test suite + upstream tools)**

- [ ]

**CNF setup Tasks**

- [ ]

**Sample CNF tasks:**

- [ ]

**Code implementation tasks:**

- [ ]

**Documentation tasks:**

- [ ] Update [Test Categories md](https://github.com/cncf/cnf-testsuite/blob/main/TEST-CATEGORIES.md) if needed
- [ ] Update [Pseudo Code md](https://github.com/cncf/cnf-testsuite/blob/main/PSEUDO-CODE.md) if needed
- [ ] Update [USAGE md](https://github.com/cncf/cnf-testsuite/blob/main/USAGE.md) if needed
- [ ] Update [installation instructions](https://github.com/cncf/cnf-testsuite/blob/main/install.md) if needed

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
