# CNF Test Rationale

**Workload Tests**

## Compatibility, Installability, and Upgradability Tests

Why: Service providers have historically had issues with the 
installability of vendor network functions.  This category tests the installability
and lifecycle management (the create, update, and delete of network applications) against 
widely used K8s installation solutions such as Helm.

* ✔️ To test the increasing and decreasing of capacity

Why: A CNF should be able to increase and decrease its capacity without running into errors

* ✔️ Test if the Helm chart is published

Why: If a helm chart is published, it is significantly easier to install for the end user.  
The management and versioning of the helm chart are handled by the helm registry and client tools
rather than manually as directly referencing the helm chart source.

* ✔️ Test if the Helm chart is valid

* ✔️ Test if the Helm deploys
    
* ✔️ Test if CNF/the install script uses Helm v3

Why: Helm v3 has significant ease-of-use improvements over helm v2, which has additional dependencies
such as tiller.  

* ✔️ To test if the CNF can perform a rolling update

* ✔️ To check if a CNF version can be downgraded through a rolling_version_change

* ✔️ To check if a CNF version can be downgraded through a rolling_downgrade

Why (update, version change, downgrade):  K8s best practice for version/installation 
management (lifecycle management) of applications is to have [K8s track the version of 
the manifest information](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#updating-a-deployment)
for the resource (deployment, pod, etc) internally.  Whenever a 
rollback is needed the resource will have the exact manifest information 
that was tied to the application when it was deployed.  This adheres the principles driving 
immutable infrastructure and declarative specifications. 

* ✔️ To check if a CNF version can be rolled back 
        
Why:  K8s best practice is to allow [K8s to manage the rolling back](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#rolling-back-a-deployment) of an application resource
instead of having operators manually rolling back the resource by using 
something like blue/green deploys. 

* ✔️ To check if the CNF is compatible with different CNIs

## Microservice Tests 

Why: [Good microservice practices](https://vmblog.com/archive/2022/01/04/the-zeitgeist-of-cloud-native-microservices.aspx)
promote agility which means less time will occur between deployments.  One benefit of more agility 
is it allows for different organizations and teams to deploy at the rate of change that they 
build out features, instead of deploying in lock step with other teams. This is very important 
when it comes to changes that are time sensitive like security patches.

* ✔️ To check if the CNF has a reasonable image size 

Why: A CNF with a large image size of 5 gig or more tends to indicate a monolithic application

* ✔️ To check if the CNF have a reasonable startup time 

Why: A CNF that starts up with a time (adjusted for server resources) that is approaching a minute 
is indicative of a monolithic application

* ✔️ To check if the CNF has multiple process types within one container

Why: A microservice should have only one process (or set of parent/child processes) that is
managed by a non home grown supervisor or orchestrator.  The microservice should not spawn 
other process types (e.g. executables) as a way to contributeto the workload but rather 
should interact with other processes through a microservice API.

* ✔️ To check if the CNF exposes any of its containers as a service 'service_discovery'

Why: A K8s microservice should expose it's API though a K8s service resource.  K8s services
handle service discovery and load balancing for the cluster.

* ✔️ To check if the CNF uses a shared database

Why: A K8s microservice should not share a database with another K8s database because
it forces the two services to upgrade in lock step

## State Tests

Why: If infrastructure is immutable, it is easily reproduced, consistent, disposable, 
will have a repeatable deployment process, and will not have configuration or artifacts that 
are modifiable in place.  This ensures that all *configuration* is stateless.  Any *data* that is 
persistent should be managed by K8s statefulsets.

* ✔️ To test if the CNF uses a volume host path

Why: When a cnf uses a volume host path or local storage it makes the application tightly coupled 
to the node that it is on.  

* ✔️ To test if the CNF uses local storage

* ✔️ To test if the CNF uses elastic volumes

Why: A cnf that uses elastic volumes can be rescheduled to other nodes by the orchestrator easily

* ✔️ To test if the CNF uses a database with either statefulsets, elastic volumes, or both

Why: When a traditional database such as mysql is configured to use statefulsets, it allows
 the database to use a persistent identifier that it maintains across any rescheduling. 
 Persistent Pod identifiers make it easier to match existing volumes to the new Pods that 
 have been rescheduled. https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/
 
* ✔️ Test if the CNF crashes when node drain occurs

Why: No CNF should fail because of stateful configuration. A CNF should function properly if it is rescheduled on other nodes.   This test will remove 
resources which are running on a target node and reschedule them on the another node.

## Reliability, Resilience and Availability

Why: Cloud native systems promote resilience by putting a high priority on testing 
individual components (chaos testing) as they are running (possibly in production).
[Reliability in traditional telecommunications](https://vmblog.com/archive/2021/09/15/cloud-native-chaos-and-telcos-enforcing-reliability-and-availability-for-telcos.aspx)
is handled differently than in Cloud Native systems. Cloud native systems try to address reliability 
(MTBF) by having the subcomponents have higher availability through higher serviceability (MTTR) 
and redundancy. For example, having ten redundant subcomponents where seven components are available 
and three have failed will produce a top level component that is more reliable (MTBF) than a single 
component that "never fails" in the cloud native world.  

* ✔️ Test if the CNF crashes when network latency occurs

Why: Network latency can have a significant impact on the overall performance of the application.  Network outages that result from low latency can cause 
a range of failures for applications and can severely impact user/customers with downtime. This chaos experiment allows you to see the impact of latency 
traffic on the CNF.

* ✔️ Test if the CNF crashes when disk fill occurs

Why: Disk Pressure is a scenario we find in Kubernetes applications that can result in the eviction of the application replica and impact its delivery. Such scenarios can still occur despite whatever availability aids K8s provides. These problems are generally referred to as "Noisy Neighbour" problems.

* ✔️ Test if the CNF crashes when pod delete occurs

Why: The CNF should recreate the minimum number of replicas when a pod fails. This experiment helps to simulate such a scenario with forced/graceful pod 
failure on specific or random replicas of an application resource.  It then checks the deployment sanity (replica availability & uninterrupted service) 
and recovery workflow of the application.

* ✔️ Test if the CNF crashes when pod memory hog occurs

Why: A CNF can fail due to running out of memory.  This can be mitigated by using two levels of memory policies (pod level and node level) 
in K8s.  If the memory policies for a CNF are not fine grained enough, the CNFs out-of-memory failure blast radius will result in 
using all of the system memory on the node.

* ✔️ Test if the CNF crashes when pod io stress occurs

Why: Stressing the disk with continuous and heavy IO can cause degradation in reads/ writes by other microservices that use this 
shared disk.  Scratch space can be used up on a node which leads to the lack of space for newer containers to get scheduled which 
causes a movement of all pods to other nodes. This test determines the limits of how a CNF uses its storage device.

* ✔️ Test if the CNF crashes when pod network corruption occurs

Why: A higher quality CNF should be resilient to a lossy/flaky network.  This test injects packet corruption on the specified CNF's container by 
starting a traffic control (tc) process with netem rules to add egress packet corruption.

* ✔️ Test if the CNF crashes when pod network duplication occurs

Why: A higher quality CNF should be resilient to erroneously duplicated packets. This test injects network duplication on the specified container 
by starting a traffic control (tc) process with netem rules to add egress delays.

* ✔️ To test if there is a liveness entry in the Helm chart

Why: A cloud native principle is that application developers understand their own 
resilience requirements better than operators[1].  This is exemplified in the Kubernetes best practice 
of pods declaring how they should be managed through the liveness and readiness entries in the 
pod's configuration. 
 
[1] "No one knows more about what an application needs to run in a healthy state than the developer. 
For a long time, infrastructure administrators have tried to figure out what “healthy” means for 
applications they are responsible for running. Without knowledge of what actually makes an 
application healthy, their attempts to monitor and alert when applications are unhealthy are 
often fragile and incomplete. To increase the operability of cloud native applications, 
applications should expose a health check."" Garrison, Justin; Nova, Kris. Cloud Native 
Infrastructure: Patterns for Scalable Infrastructure and Applications in a Dynamic 
Environment . O'Reilly Media. Kindle Edition. 

* ✔️ To test if there is a readiness entry in the Helm chart

## Observability and Diagnostic Tests

Why: In order to maintain, debug, and have insight into a production environment that is protected 
(versioned, kept in source control, and changed only by using a deployment pipeline), its 
infrastructure elements must have the property of being observable. This means these elements must 
externalize their internal states in some way that lends itself to metrics, tracing, and logging.
 
* ✔️ To check if logs are being sent to stdout/stderr (standard out, standard error) instead of a log file

Why: By sending logs to standard out/standard error 
["logs will be treated like event streams"](https://12factor.net/) as recommended by 12 
factor apps principles.

* ✔️ To check if prometheus is installed and configured for the cnf

Why: Recording metrics within a cloud native deployment is important because it gives 
the maintainer of a cluster of hundreds or thousands of services the ability to pinpoint 
[small anomalies](https://about.gitlab.com/blog/2018/09/27/why-all-organizations-need-prometheus/), 
such as those that will eventually cause a failure.

* ✔️ To check if logs and data are being routed through fluentd

* ✔️ To check if OpenMetrics is being used and or compatible.

* ✔️ To check if tracing is being used with Jaeger.

## Security Tests 

Why: *Cloud native security is a [...] mutifaceted topic [...] with multiple, diverse components 
that need to be secured. The cloud platform, the underlying host operating system, the 
container runtime, the container orchestrator,and then the applications themselves each 
require specialist security attention* -- Chris Binne, Rory Mccune. Cloud Native Security.  
(Wiley, 2021)(pp. xix)

* ✔️ To check if any containers are running as a root user (checks the user outside the container that is running dockerd)

Why: *Even with other security controls used within a Linux system running containers, 
such as namespaces that segregate access between pods in Kubernetes and OpenShift or 
containers within a runtime, it is highly advisable never to run a container as the 
root user."* Binnie, Chris; McCune, Rory (2021-06-17T23:58:59). Cloud Native Security . 
Wiley. Kindle Edition. 

* ✔️ To check if any containers allow for privilege escalation

Why: *When [privilege escalation](https://kubernetes.io/docs/concepts/policy/pod-security-policy/#privilege-escalation) is [enabled for a container](https://hub.armo.cloud/docs/c-0016), it will allow setuid binaries to change the effective user ID, allowing processes to turn on extra capabilities. 
In order to prevent illegitimate escalation by processes and restrict a processes to a NonRoot user mode, escalation must be disabled.*

* ✔️ To check if an attacker can use a symlink for arbitrary host file system access (CVE-2021-25741)

Why: *Due to CVE-2021-25741, subPath or subPathExpr volume mounts can be [used to gain unauthorised access](https://hub.armo.cloud/docs/c-0058) to files and directories anywhere on the host filesystem. In order to follow a best-practice security standard and prevent unauthorised data access, there should be no active CVEs affecting either the container or underlying platform.*

* ✔️ To check if there is a host network attached to a pod

Why: *When a container has the [hostNetwork](https://hub.armo.cloud/docs/c-0041) feature turned on, the container has direct access to the underlying hostNetwork. Hackers frequently exploit this feature to [facilitate a container breakout](https://media.defense.gov/2021/Aug/03/2002820425/-1/-1/1/CTR_KUBERNETES%20HARDENING%20GUIDANCE.PDF) and gain access to the underlying host network, data and other integral resources.*

* ✔️ To check if there are service accounts that are automatically mapped

Why: *When a pod gets created and a service account wasn't specified, then the default service account will be used. Service accounts assigned in this way can unintentionally give third-party applications root access to the K8s APIs and other applicaton services. In order to follow a zero-trust / fine-grained security methodology, this functionality will need to be [explicitly disabled](https://hub.armo.cloud/docs/c-0034) by using the [automountServiceAccountToken: false](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/#use-the-default-service-account-to-access-the-api-server) flag. In addition, if RBAC is not enabled, the SA has unlimited permissions in the cluster.*

* ✔️ To check if there is an ingress and egress policy defined.

Why: *By default, [no network policies are applied](https://hub.armo.cloud/docs/c-0030) to Pods or namespaces, resulting in unrestricted ingress and egress traffic within the Pod network. In order to [prevent lateral movement](https://media.defense.gov/2021/Aug/03/2002820425/-1/-1/1/CTR_KUBERNETES%20HARDENING%20GUIDANCE.PDF) or escalation on a compromised cluster, administrators should implement a default policy to deny all ingress and egress traffic. This will ensure that all Pods are isolated by default and further policies could then be used to specifically relax these restrictions on a case-by-case basis.*


* ✔️ To check if there are any privileged containers (kubscape version)

Why: *... docs describe Privileged mode as essentially enabling “…access to all devices on the host 
as well as [having the ability to] set some configuration in AppArmor or SElinux to allow the 
container nearly all the same access to the host as processes running outside containers on the 
host.” In other words, you should rarely, if ever, use this switch on your container command line.*
Binnie, Chris; McCune, Rory (2021-06-17T23:58:59). Cloud Native Security . Wiley. Kindle Edition. 

* ✔️ To check for insecure capabilities

* ✔️ To check for dangerous capabilities

* ✔️ To check if namespaces have network policies defined

* ✔️ To check if containers are running with non-root user with non-root membership (to do: check to see if this is a duplicate of 244)
    (this is for the users inside the container)

* ✔️ To check if containers are running with hostPID or hostIPC privileges

* ✔️ To check if security services are being used to harden containers

* ✔️ To check if containers have resource limits defined

* ✔️ To check if containers have immutable file systems

* ✔️ To check if containers have hostPath mounts (check: is this a duplicate of state test - ./cnf-testsuite volume_hostpath_not_found)



## Configuration Tests 
Why: Declarative APIs for an immutable infrastructure are anything that configures 
the infrastructure element. This declaration can come in the form of a YAML file or a script, 
as long as the configuration designates the desired outcome, not how to achieve said outcome. 
*"Because it describes the state of the world, declarative configuration does not have to be 
executed to be understood. Its impact is concretely declared. Since the effects of declarative 
configuration can be understood before they are executed, declarative configuration is far less 
error-prone. " --Hightower, Kelsey; Burns, Brendan; Beda, Joe. Kubernetes: Up and 
Running: Dive into the Future of Infrastructure (Kindle Locations 183-186). Kindle Edition*

* ✔️ To test if there are versioned tags on all images using OPA Gatekeeper

Why: *"You should [avoid using the :latest tag](https://kubernetes.io/docs/concepts/containers/images/)
when deploying containers in production as it is harder to track which version of the image 
is running and more difficult to roll back properly."*

* ✔️ To test if there are node ports used in the service configuration


Why: Using node ports ties the CNF to a specific node and therefore makes the CNF less
portable and scalable

* ✔️ To test if there are host ports used in the service configuration


Why: Using host ports ties the CNF to a specific node and therefore makes the CNF less
portable and scalable

* ✔️ To test if there are any (non-declarative) hardcoded IP addresses or subnet masks in the K8s runtime configuration


Why: Using a hard coded IP in a CNF's configuration designates *how* (imperative) a CNF should 
achieve a goal, not *what* (declarative) goal the CNF should achieve

* ✔️ To check if a CNF uses K8s secrets


Why: If a CNF uses kubernetes K8s secrets instead of unencrypted environment 
variables or configmaps, there is [less risk of the Secret (and its data) being 
exposed](https://kubernetes.io/docs/concepts/configuration/secret/) during the 
workflow of creating, viewing, and editing Pods

* ✔️ To check if a CNF version uses immutable configmaps

Why: *"For clusters that extensively use ConfigMaps (at least tens of thousands of unique ConfigMap to Pod mounts), 
[preventing changes](https://kubernetes.io/docs/concepts/configuration/configmap/#configmap-immutable)
to their data has the following advantages:*
- *protects you from accidental (or unwanted) updates that could cause applications outages*
- *improves performance of your cluster by significantly reducing load on kube-apiserver, by 
closing watches for ConfigMaps marked as immutable.*"

*  (Maybe/PoC) To check if a CNF uses Kubernetes alpha APIs 'alpha_k8s_apis'

Why: If a CNF uses alpha or undocumented APIs, the CNF is tightly coupled to an unstable platform

