# CNF Conformance
The goal of the CNF Conformance Program is to provide an open source test suite to demonstrate conformance and implementation of cloud native best practices for both open and closed source Cloud Native Network Functions. The conformance program is a living thing. The CNCF community, through the [Cloud Native Network Function Working Group](cnf-wg/README.md), oversees and maintains what it means to be a cloud native conformant telco application (including those applications called network functions). It also develops the process and policy around the certification program. Work on the mechanics of the conformance tests occurs in the [CNF Conformance Test Suite](README-testsuite.md).

## Why Conformance Matters
With such a wide array of applications being developed today, workload conformance tests help ensure that developers can follow cloud native best practices when building greenfield applications and/or modernizing existing applications. A conformance passing application provides the following guarantees:

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
- **Resilience** - CNFs should be resilient to failures inevitable in cloud environments. CNF Resilience should be tested to ensure CNFs are designed to deal with non-carrier-grade shared cloud HW/SW platform.
- **Optimal Resource Allocation** - CNFs should use integer resources and guranteed QOS class type whenever possible to avoid resource contention  

Best practices: Your application follows cloud native best practices. This is useful to know whether you are building upon the work of the community or handling your own custom setup.

Predictability: Your application acts in a predictable manner when running on cloud native infrastructure like Kubernetes. Unexpected behavior should be rare, because application specific issues are weeded out during the conformance tests.

Interoperability: Workloads can be ported across various cloud native infrastructures. This standardization is a key advantage of open source software, and allows you to avoid vendor lock-in.

Implementing and running applications in a cloud native manner will enable you to more fully benefit from the advantages cloud native infrastructure.

## CNF Conformance Program

- Instructions - TBD
- FAQ - TBD

## Working Group Information

To participate and contribute to the program itself (including discussion of
issues affecting conformance and certification), join the mailing list and
slack channel. Details: [Conformance WG](cnf-wg/README.md).

## Test Suite Information

To contribute to or use the test suite you can join the slack channel, weekly meetings, and interact in github. Details: [Test suite](README-testsuite.md).
