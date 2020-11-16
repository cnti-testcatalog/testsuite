# Cloud Native Network Functions Working Group Charter

## Introduction
The goal of the Cloud Native Network Functions Working Group (CNF WG)  is to aid companies such as telecom vendors, communications service providers and large scale enterprises, running internal telecommunications-like infrastructure, to better understand what cloud native means for telecommunications workloads and help build consensus around industry adoption of cloud native technologies (per CNCF TUG).

The CNF WG operates under the aegis of CNCF. The charter of the working group is to define the process around certifying the cloud nativeness of telco applications, aka CNFs. We collaborate with the cncf/cnf-conformance test suite who work on the mechanics of the conformance tests.

The goal for the group is to create a software conformance program that any application or network function implementation can use to demonstrate that they are conformant and interoperable with cloud native principles.

## Mission Statement
Cloud Native Network Functions Working Group’s mission is to increase interoperability and standardization of cloud native workloads. It is committed to the following (aspirational) design ideals:
- Portable - Cloud native workloads run everywhere -- public cloud, private cloud, bare metal, laptop -- with consistent functional behavior so that they are portable throughout the ecosystem as well as between development and production environments.
- Meet users partway. Many applications today are not cloud native, but have been working in production for decades. The WG doesn’t just cater to purely greenfield cloud-native applications, nor does it meet all users where they are. It focuses on cloud-native applications, but provides some mechanisms to facilitate migration of monolithic and legacy applications.
- Flexible. The cloud native technology ecosystem can be consumed a la carte and (in most cases) it does not prevent you from using your own solutions in lieu of built-in systems.
- Extensible. Cloud native workloads should integrate into your environment and add the additional capabilities you need.
- Automatable. Cloud native workloads should aim to help dramatically reduce the burden of manual operations. They support both declarative control by specifying users’ desired intent via an API, as well as imperative control to support higher-level orchestration and automation. The declarative approach is key to the ecosystem’s self-healing and autonomic capabilities.
- Advance the state of the art. While the WG intends to drive the modernization of non-cloud-native applications, it also aspires to advance the cloud native and DevOps state of the art, such as in the participation of applications in their own management. Workloads should not be bound by the lowest common denominator of systems upon which they depend, such as container runtimes and cloud providers.

## In Scope
- Definition of Cloud native Network Function (CNF)
- Cloud native conformance test requirements for CNFs
  - Including dataplane CNFs
- Process around certifying CNF conformance
- Feedback into other related groups and specification bodies to improve CNF use cases (e.g. SIG App Delivery, SIG Networking, CNI)
- Publishing metrics/white papers
- Best Practices and General Recommendations

## Potential Future Scope
- Cloud native conformance requirements for Telco platforms (which run CNFs)

## Out of Scope

- Writing conformance tests or a test suite
- Building Tooling
- Promotion of specific tools
- Solving external dependencies


## Overlap and Relations with other Groups and Projects
The CNF WG sees itself as providing the upstream definition of what makes a telco application cloud native allowing downstream projects to create precise programs and/or implementations for their specific needs. Some of the groups who may utilize the CNF Conformance Programs deliverables are:

- CNTT R2 - is focused on Kubernetes-based platforms and basic interoperability between platform and workloads. CNTT R2 has not determined if workload cloud native requirements are in scope for CNTT R2. It is expecting CNCF to provide testing for the cloud native requirements it has defined. 
- OVP 2.0 (Cloud Native) - is interested in leveraging an upstream source for cloud native requirements and test results (like deliverables from the CNCF CNF WG) to be used in the OVP 2.0 Badging Program.

Telco applications and the workloads that are created with them are related to many topics in Cloud Native computing; therefore this WG may collaborate with many of the other CNCF and K8s SIGs, WGs, and projects. A few of the groups with potential interactions/collaboration are:

- CNCF SIG App Delivery
- CNCF SIG Security 
- CNCF SIG Network
- Kubernetes SIG Apps
- Kubernetes SIG Testing
- K8s Conformance WG

## Responsibilities and Deliverables

Responsibilities

The CNCF community, through CNF WG, is in charge of what it means to be a Certified cloud native workload -- with a focus on networking and telecom workloads. 
The CNF WG creates and maintains the definitions, processes, as well as policies around the certification program. It determines what best pratices and cloud native principles are required to be conformant.

The work on the mechanics of the conformance tests, implementation of tests which validate conformance, and the test framework itself occurs in [CNF test suite project](/cncf/cnf-conformance/README-testsuite.md) itself -- not in the working  group.

Deliverables
- Cloud native principles - framework documentation for cloud native requirements 
- Networking application cloud native requirements - including documentation, test definitions, best pratices
- Cloud native network function conformance program


## Governance and Operations

### Operating Model
#### Chairs:
- TBD

#### Communications
- Slack Channel (#sig-network)
- Join CNF-WG mailer at lists.cncf.io
- Repo: TBD
- Meetings:TBD
