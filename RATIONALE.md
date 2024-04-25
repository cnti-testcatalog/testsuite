# CNF Test Rationale

**Workload Tests**

## Compatibility, Installability, and Upgradability Tests

#### Service providers have historically had issues with the installability of vendor network functions.  This category tests the installabilityand lifecycle management (the create, update, and delete of network applications) against widely used K8s installation solutions such as Helm.
***

#### *To test the increasing and decreasing of capacity*: [increase_decrease_capacity](docs/LIST_OF_TESTS.md#increase-decrease-capacity)
> A CNF should be able to increase and decrease its capacity without running into errors.

#### *Test if the Helm chart is published*: [helm_chart_published](docs/LIST_OF_TESTS.md#helm-chart-published)
> If a helm chart is published, it is significantly easier to install for the end user.  
The management and versioning of the helm chart are handled by the helm registry and client tools
rather than manually as directly referencing the helm chart source.

#### *Test if the Helm chart is valid*: [helm_chart_valid](docs/LIST_OF_TESTS.md#helm-chart-valid)
> A chart should pass the [lint specification](https://helm.sh/docs/helm/helm_lint/#helm)

#### *Test if the Helm deploys*: [helm_deploy](docs/LIST_OF_TESTS.md#helm-deploy)
> A helm chart should be [deployable to a cluster](https://helm.sh/docs/helm/helm_install/#helm)

#### *To check if a CNF version can be rolled back*: [rollback](docs/LIST_OF_TESTS.md#rollback)
> K8s best practice is to allow [K8s to manage the rolling back](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#rolling-back-a-deployment) of an application resource instead of having operators manually rolling back the resource by using something like blue/green deploys. 

#### *To test if the CNF can perform a rolling update*: [rolling_update](docs/LIST_OF_TESTS.md#rolling-update)
> See rolling downgrade

#### *To check if a CNF version can be downgraded through a rolling_version_change*: [rolling_version_change](docs/LIST_OF_TESTS.md#rolling-version-change)
> See rolling downgrade

#### *To check if a CNF version can be downgraded through a rolling_downgrade*: [rolling_downgrade](docs/LIST_OF_TESTS.md#rolling-downgrade)
> (update, version change, downgrade):  K8s best practice for version/installation 
management (lifecycle management) of applications is to have [K8s track the version of 
the manifest information](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#updating-a-deployment)
for the resource (deployment, pod, etc) internally.  Whenever a 
rollback is needed the resource will have the exact manifest information 
that was tied to the application when it was deployed.  This adheres the principles driving 
immutable infrastructure and declarative specifications. 

#### *To check if the CNF is compatible with different CNIs*: [cni_compatibility](docs/LIST_OF_TESTS.md#cni-compatible)
> A CNF should be runnable by any CNI that adheres to the [CNI specification](https://github.com/containernetworking/cni/blob/master/SPEC.md)

#### *[POC] To check if a CNF uses Kubernetes alpha APIs 'alpha_k8s_apis'*: [alpha_k8s_apis](docs/LIST_OF_TESTS.md#kubernetes-alpha-apis---proof-of-concept)

> If a CNF uses alpha or undocumented APIs, the CNF is tightly coupled to an unstable platform

## Microservice Tests 

#### [Good microservice practices](https://vmblog.com/archive/2022/01/04/the-zeitgeist-of-cloud-native-microservices.aspx) promote agility which means less time will occur between deployments.  One benefit of more agility is it allows for different organizations and teams to deploy at the rate of change that they build out features, instead of deploying in lock step with other teams. This is very important when it comes to changes that are time sensitive like security patches.
***

#### *To check if the CNF has a reasonable image size*: [reasonable_image_size](docs/LIST_OF_TESTS.md#reasonable-image-size)

> A CNF with a large image size of 5 gig or more tends to indicate a monolithic application

#### *To check if the CNF have a reasonable startup time*: [reasonable_startup_time](docs/LIST_OF_TESTS.md#reasonable-startup-time)

> A CNF that starts up with a time (adjusted for server resources) that is approaching a minute 
is indicative of a monolithic application.  The liveness probe's initialDelaySeconds and failureThreshhold determine the startup time and retry amount of the CNF.
Specifically, if the initiaDelay is too long it is indicative of a monolithic application.  If the failureThreshold is too high it is indicative of a CNF or a component of the CNF that has too many intermittent failures.

#### *To check if the CNF has multiple process types within one container*: [single_process_type](docs/LIST_OF_TESTS.md#single-process-type-in-one-container)

> A microservice should have only one process (or set of parent/child processes) that is
managed by a non home grown supervisor or orchestrator.  The microservice should not spawn 
other process types (e.g. executables) as a way to contributeto the workload but rather 
should interact with other processes through a microservice API.

#### *To check if the CNF exposes any of its containers as a service 'service_discovery'*: [service_discovery](docs/LIST_OF_TESTS.md#service-discovery)

> A K8s microservice should expose it's API though a K8s service resource.  K8s services
handle service discovery and load balancing for the cluster.

#### *To check if the CNF uses a shared database*: [shared_database](docs/LIST_OF_TESTS.md#shared-database)

> A K8s microservice should not share a database with another K8s database because
it forces the two services to upgrade in lock step

#### *To check if the CNF uses container images with specialized init systems*: [specialized_init_systems](docs/LIST_OF_TESTS.md#specialized-init-systems)

> There are proper init systems and sophisticated supervisors that can be run inside of a container. Both of these systems properly reap and pass signals. Sophisticated supervisors are considered overkill because they take up too many resources and are sometimes too complicated. Some examples of sophisticated supervisors are: supervisord, monit, and runit. Proper init systems are smaller than sophisticated supervisors and therefore suitable for containers. Some of the proper container init systems are tini, dumb-init, and s6-overlay.

#### *To check if the CNF PID 1 processes handle SIGTERM*: [sigterm_handled](docs/LIST_OF_TESTS.md#sig-term-handled)

> The Linux kernel handles signals differently for the process that has PID 1 than it does for other processes. Signal handlers aren't automatically registered for this process, meaning that signals such as SIGTERM or SIGINT will have no effect by default. By default, one must kill processes by using SIGKILL, preventing any graceful shutdown. Depending on the application, using SIGKILL can result in user-facing errors, interrupted writes (for data stores), or unwanted alerts in a monitoring system.

#### *To check if the CNF PID 1 processes handle zombie processes correctly*: [zombie_handled](docs/LIST_OF_TESTS.md#zombie-handled)

> Classic init systems such as systemd are also used to remove (reap) orphaned, zombie processes. Orphaned processes — processes whose parents have died - are reattached to the process that has PID 1, which should reap them when they die. A normal init system does that. But in a container, this responsibility falls on whatever process has PID 1. If that process doesn't properly handle the reaping, you risk running out of memory or some other resources.

## State Tests

#### If infrastructure is immutable, it is easily reproduced, consistent, disposable, will have a repeatable deployment process, and will not have configuration or artifacts that are modifiable in place.  This ensures that all *configuration* is stateless.  Any [*data* that is persistent](https://vmblog.com/archive/2022/05/16/stateful-cnfs.aspx) should be managed by K8s statefulsets.
***

#### *Test if the CNF crashes when node drain occurs*: [node_drain](docs/LIST_OF_TESTS.md#node-drain)

> No CNF should fail because of stateful configuration. A CNF should function properly if it is rescheduled on other nodes.   This test will remove 
resources which are running on a target node and reschedule them on the another node.


#### *To test if the CNF uses a volume host path*: [volume_hostpath_not_found](docs/LIST_OF_TESTS.md#volume-hostpath-not-found)

> When a cnf uses a volume host path or local storage it makes the application tightly coupled 
to the node that it is on.  

#### *To test if the CNF uses local storage*: [no_local_volume_configuration](docs/LIST_OF_TESTS.md#no-local-volume-configuration)
> A CNF should refrain from using the [local storage class](https://kubernetes.io/docs/concepts/storage/storage-classes/#local)

#### *To test if the CNF uses elastic volumes*: [elastic_volumes](docs/LIST_OF_TESTS.md#elastic-volumes)

> A cnf that uses elastic volumes can be rescheduled to other nodes by the orchestrator easily

#### *To test if the CNF uses a database with either statefulsets, elastic volumes, or both*: [database_persistence](docs/LIST_OF_TESTS.md#database-persistence)

> When a traditional database such as mysql is configured to use statefulsets, it allows
 the database to use a persistent identifier that it maintains across any rescheduling. 
 Persistent Pod identifiers make it easier to match existing volumes to the new Pods that 
 have been rescheduled. https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/
 
## Reliability, Resilience and Availability

#### Cloud native systems promote resilience by putting a high priority on testing individual components (chaos testing) as they are running (possibly in production).[Reliability in traditional telecommunications](https://vmblog.com/archive/2021/09/15/cloud-native-chaos-and-telcos-enforcing-reliability-and-availability-for-telcos.aspx) is handled differently than in Cloud Native systems. Cloud native systems try to address reliability (MTBF) by having the subcomponents have higher availability through higher serviceability (MTTR) and redundancy. For example, having ten redundant subcomponents where seven components are available and three have failed will produce a top level component that is more reliable (MTBF) than a single component that "never fails" in the cloud native world.  

#### *Test if the CNF crashes when network latency occurs*: [pod_network_latency](docs/LIST_OF_TESTS.md#cnf-under-network-latency)

> Network latency can have a significant impact on the overall performance of the application.  Network outages that result from low latency can cause 
a range of failures for applications and can severely impact user/customers with downtime. This chaos experiment allows you to see the impact of latency 
traffic on the CNF.

#### *Test if the CNF crashes when disk fill occurs*: [disk_fill](docs/LIST_OF_TESTS.md#cnf-with-host-disk-fill)

> Disk Pressure is a scenario we find in Kubernetes applications that can result in the eviction of the application replica and impact its delivery. Such scenarios can still occur despite whatever availability aids K8s provides. These problems are generally referred to as "Noisy Neighbour" problems.

#### *Test if the CNF crashes when pod delete occurs*: [pod_delete](docs/LIST_OF_TESTS.md#pod-delete)

> In a distributed system like Kubernetes, application replicas may not be sufficient to manage the traffic (indicated by SLIs) when some replicas are unavailable due to any failure (can be system or application). The application needs to meet the SLO (service level objectives) for this. It's imperative that the application has defenses against this sort of failure to ensure that the application always has a minimum number of available replicas. 


#### *Test if the CNF crashes when pod memory hog occurs*: [pod_memory_hog](docs/LIST_OF_TESTS.md#memory-hog)

> If the memory policies for a CNF are not set and granular, containers on the node can be killed based on their oom_score and the QoS class a given pod belongs to (best-effort ones are first to be targeted). This eval is extended to all pods running on the node, thereby causing a bigger blast radius. 

#### *Test if the CNF crashes when pod io stress occurs*: [pod_io_stress](docs/LIST_OF_TESTS.md#io-stress)

> Stressing the disk with continuous and heavy IO can cause degradation in reads/ writes by other microservices that use this 
shared disk.  Scratch space can be used up on a node which leads to the lack of space for newer containers to get scheduled which 
causes a movement of all pods to other nodes. This test determines the limits of how a CNF uses its storage device.

#### *Test if the CNF crashes when pod network corruption occurs*: [pod_network_corruption](docs/LIST_OF_TESTS.md#network-corruption)

> A higher quality CNF should be resilient to a lossy/flaky network.  This test injects packet corruption on the specified CNF's container by 
starting a traffic control (tc) process with netem rules to add egress packet corruption.

#### *Test if the CNF crashes when pod network duplication occurs*: [pod_network_duplication](docs/LIST_OF_TESTS.md#network-duplication)

> A higher quality CNF should be resilient to erroneously duplicated packets. This test injects network duplication on the specified container 
by starting a traffic control (tc) process with netem rules to add egress delays.

#### *Test if the CNF crashes when DNS errors occur*: [pod_dns_errors](docs/LIST_OF_TESTS.md#pod-dns-errors)

> A CNF should be resilient to name resolution (DNS) disruptions within the kubernetes pod. This ensures that at least some application availability will be maintained if DNS resolution fails.

#### *To test if there is a liveness entry in the Helm chart*: [liveness](docs/LIST_OF_TESTS.md#helm-chart-liveness-entry)

> A cloud native principle is that application developers understand their own 
resilience requirements better than operators[1].  This is exemplified in the Kubernetes best practice 
of pods declaring how they should be managed through the liveness and readiness entries in the 
pod's configuration. 
 
> [1] "No one knows more about what an application needs to run in a healthy state than the developer. 
For a long time, infrastructure administrators have tried to figure out what “healthy” means for 
applications they are responsible for running. Without knowledge of what actually makes an 
application healthy, their attempts to monitor and alert when applications are unhealthy are 
often fragile and incomplete. To increase the operability of cloud native applications, 
applications should expose a health check."" Garrison, Justin; Nova, Kris. Cloud Native 
Infrastructure: Patterns for Scalable Infrastructure and Applications in a Dynamic 
Environment . O'Reilly Media. Kindle Edition. 

#### *To test if there is a readiness entry in the Helm chart*: [readiness](docs/LIST_OF_TESTS.md#helm-chart-readiness-entry)

> A CNF should tell Kubernetes when it is [ready to serve traffic](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-readiness-probes).

## Observability and Diagnostic Tests

#### In order to maintain, debug, and have insight into a production environment that is protected (versioned, kept in source control, and changed only by using a deployment pipeline), its infrastructure elements must have the property of being observable. This means these elements must externalize their internal states in some way that lends itself to metrics, tracing, and logging.
 
#### *To check if logs are being sent to stdout/stderr (standard out, standard error) instead of a log file*: [log_output](docs/LIST_OF_TESTS.md#use-stdoutstderr-for-logs)

> By sending logs to standard out/standard error 
["logs will be treated like event streams"](https://12factor.net/) as recommended by 12 
factor apps principles.

#### *To check if prometheus is installed and configured for the cnf*: [prometheus_traffic](docs/LIST_OF_TESTS.md#prometheus-installed)

> Recording metrics within a cloud native deployment is important because it gives 
the maintainer of a cluster of hundreds or thousands of services the ability to pinpoint 
[small anomalies](https://about.gitlab.com/blog/2018/09/27/why-all-organizations-need-prometheus/), 
such as those that will eventually cause a failure.

#### *To check if logs and data are being routed through a Unified Logging Layer*: [routed_logs](docs/LIST_OF_TESTS.md#routed-logs)
> A CNF should have logs managed by a [unified logging layer](https://www.fluentd.org/why) It's considered a best-practice for CNFs to route logs and data through programs like fluentd to analyze and better understand data.

#### *To check if OpenMetrics is being used and or compatible.*: [open_metrics](docs/LIST_OF_TESTS.md#openmetrics-compatible)
> OpenMetrics is the de facto standard for transmitting cloud native metrics at scale, with support for both text representation and Protocol Buffers and brings it into an Internet Engineering Task Force (IETF) standard. A CNF should expose metrics that are [OpenMetrics compatible](https://github.com/OpenObservability/OpenMetrics/blob/main/specification/OpenMetrics.md)

#### *To check if tracing is being used with Jaeger.*: [tracing](docs/LIST_OF_TESTS.md#jaeger-tracing)
> A CNF should provide tracing that conforms to the [open telemetry tracing specification](https://opentelemetry.io/docs/reference/specification/trace/api/)
>  
## Security Tests 

#### *"Cloud native security is a [...] mutifaceted topic [...] with multiple, diverse components that need to be secured. The cloud platform, the underlying host operating system, the container runtime, the container orchestrator,and then the applications themselves each require specialist security attention"* -- Chris Binne, Rory Mccune. Cloud Native Security. (Wiley, 2021)(pp. xix)*

#### *To check if the cnf performs a CRI socket mount*: [container_sock_mounts](docs/LIST_OF_TESTS.md#container-socket-mounts)

> *[Container daemon socket bind mounts](https://kyverno.io/policies/best-practices/disallow_cri_sock_mount/disallow_cri_sock_mount/) allows access to the container engine on the node. This access can be used for privilege escalation and to manage containers outside of Kubernetes, and hence should not be allowed..*

#### *To check if there are any privileged containers*: [privileged_containers](docs/LIST_OF_TESTS.md#privileged-containers)

> *... docs describe Privileged mode as essentially enabling “…access to all devices on the host 
as well as [having the ability to] set some configuration in AppArmor or SElinux to allow the 
container nearly all the same access to the host as processes running outside containers on the 
host.” In other words, you should rarely, if ever, use this switch on your container command line.*
Binnie, Chris; McCune, Rory (2021-06-17T23:58:59). Cloud Native Security . Wiley. Kindle Edition. 


#### *To check if External IPs are used for services*: [external_ips](docs/LIST_OF_TESTS.md#external-ips)

> Service externalIPs can be used for a MITM attack (CVE-2020-8554). Restrict externalIPs or limit to a known set of addresses. See: https://github.com/kyverno/kyverno/issues/1367

#### *To check if any containers allow for privilege escalation*: [privilege_escalation](docs/LIST_OF_TESTS.md#privilege-escalation)

> *When [privilege escalation](https://kubernetes.io/docs/concepts/policy/pod-security-policy/#privilege-escalation) is [enabled for a container](https://hub.armo.cloud/docs/c-0016), it will allow setuid binaries to change the effective user ID, allowing processes to turn on extra capabilities. 
In order to prevent illegitimate escalation by processes and restrict a processes to a NonRoot user mode, escalation must be disabled.*

#### *To check if an attacker can use a symlink for arbitrary host file system access (CVE-2021-25741)*: [symlink_file_system](docs/LIST_OF_TESTS.md#symlink-file-system)

> *Due to CVE-2021-25741, subPath or subPathExpr volume mounts can be [used to gain unauthorised access](https://hub.armo.cloud/docs/c-0058) to files and directories anywhere on the host filesystem. In order to follow a best-practice security standard and prevent unauthorised data access, there should be no active CVEs affecting either the container or underlying platform.*

#### *To check if selinux has been configured properly*: [selinux_options](docs/LIST_OF_TESTS.md#selinux-options)
> If [SELinux options](https://kyverno.io/policies/pod-security/baseline/disallow-selinux/disallow-selinux/) is configured improperly it can be used to escalate privileges and should not be allowed.

#### *To check if any pods in the CNF use sysctls with restricted values*: [sysctls](docs/LIST_OF_TESTS.md#sysctls)
> Sysctls can disable security mechanisms or affect all containers on a host, and should be disallowed except for an allowed "safe" subset. A sysctl is considered safe if it is namespaced in the container or the Pod, and it is isolated from other Pods or processes on the same Node. This test ensures that only those "safe" subsets are specified in a Pod.

#### *To check if there are applications credentials in configuration files*: [application_credentials](docs/LIST_OF_TESTS.md#application-credentials)

> *Developers store secrets in the Kubernetes configuration files, such as environment variables in the pod configuration. Such behavior is commonly seen in clusters that are monitored by Azure Security Center. Attackers who have access to those configurations, by querying the API server or by accessing those files on the developer’s endpoint, can steal the stored secrets and use them.*

#### *To check if there is a host network attached to a pod*: [host_network](docs/LIST_OF_TESTS.md#host-network)

> *When a container has the [hostNetwork](https://hub.armo.cloud/docs/c-0041) feature turned on, the container has direct access to the underlying hostNetwork. Hackers frequently exploit this feature to [facilitate a container breakout](https://media.defense.gov/2021/Aug/03/2002820425/-1/-1/1/CTR_KUBERNETES%20HARDENING%20GUIDANCE.PDF) and gain access to the underlying host network, data and other integral resources.*


#### *To check if there is automatic mapping of service accounts*: [service_account_mapping](docs/LIST_OF_TESTS.md#service-account-mapping)

> *When a pod gets created and a service account wasn't specified, then the default service account will be used. Service accounts assigned in this way can unintentionally give third-party applications root access to the K8s APIs and other applicaton services. In order to follow a zero-trust / fine-grained security methodology, this functionality will need to be explicitly disabled by using the automountServiceAccountToken: false flag. In addition, if RBAC is not enabled, the SA has unlimited permissions in the cluster.*


#### *To check if there is an ingress and egress policy defined.*: [ingress_egress_blocked](docs/LIST_OF_TESTS.md#ingress-and-egress-blocked)

> *By default, [no network policies are applied](https://hub.armo.cloud/docs/c-0030) to Pods or namespaces, resulting in unrestricted ingress and egress traffic within the Pod network. In order to [prevent lateral movement](https://media.defense.gov/2021/Aug/03/2002820425/-1/-1/1/CTR_KUBERNETES%20HARDENING%20GUIDANCE.PDF) or escalation on a compromised cluster, administrators should implement a default policy to deny all ingress and egress traffic. This will ensure that all Pods are isolated by default and further policies could then be used to specifically relax these restrictions on a case-by-case basis.* 


#### *To check for insecure capabilities*: [insecure_capabilities](docs/LIST_OF_TESTS.md#insecure-capabilities)
> Giving [insecure](https://hub.armo.cloud/docs/c-0046) and unnecessary capabilities for a container can increase the impact of a container compromise.

#### *To check if containers are running with non-root user with non-root membership*: [non_root_containers](docs/LIST_OF_TESTS.md#non-root-containers)
> Container engines allow containers to run applications as a non-root user with non-root group membership. Typically, this non-default setting is configured when the container image is built. . Alternatively, Kubernetes can load containers into a Pod with SecurityContext:runAsUser specifying a non-zero user. While the runAsUser directive effectively forces non-root execution at deployment, [NSA and CISA encourage developers](https://hub.armo.cloud/docs/c-0013) to build container applications to execute as a non-root user. Having non-root execution integrated at build time provides better assurance that applications will function correctly without root privileges.

#### *To check if containers are running with hostPID or hostIPC privileges*: [host_pid_ipc_privileges](docs/LIST_OF_TESTS.md#host-pidipc-privileges)
> Containers should be isolated from the host machine as much as possible. The [hostPID and hostIPC](https://hub.armo.cloud/docs/c-0038) fields in deployment yaml may allow cross-container influence and may expose the host itself to potentially malicious or destructive actions. This control identifies all PODs using hostPID or hostIPC privileges.

#### *To check if security services are being used to harden containers*: [linux_hardening](docs/LIST_OF_TESTS.md#linux-hardening)
> In order to reduce the attack surface, it is recommend, when it is possible, to harden your application using [security services](https://hub.armo.cloud/docs/c-0055) such as SELinux®, AppArmor®, and seccomp. Starting from Kubernetes version 1.22, SELinux is enabled by default.

#### *To check if containers have resource limits defined*: [resource_policies](docs/LIST_OF_TESTS.md#resource-policies)
> CPU and memory [resources should have a limit](https://hub.armo.cloud/docs/c-0009) set for every container or a namespace to prevent resource exhaustion. This control identifies all the Pods without resource limit definitions by checking thier yaml definition file as well as their namespace LimitRange objects. It is also recommended to use ResourceQuota object to restrict overall namespace resources, but this is not verified by this control.

#### *To check if containers have immutable file systems*: [immutable_file_systems](docs/LIST_OF_TESTS.md#immutable-file-systems)
> Mutable container filesystem can be abused to gain malicious code and data injection into containers. By default, containers are permitted unrestricted execution within their own context. An attacker who has access to a container, [can create files](https://hub.armo.cloud/docs/c-0017) and download scripts as they wish, and modify the underlying application running on the container.

#### *To check if containers have hostPath mounts (check: is this a duplicate of state test - ./cnf-testsuite volume_hostpath_not_found)*: [hostpath_mounts](docs/LIST_OF_TESTS.md#hostpath-mounts)
> [hostPath mount](https://hub.armo.cloud/docs/c-0006) can be used by attackers to get access to the underlying host and thus break from the container to the host. (See “3: Writable hostPath mount” for details).


## Configuration Tests 
#### Declarative APIs for an immutable infrastructure are anything that configures the infrastructure element. This declaration can come in the form of a YAML file or a script, as long as the configuration designates the desired outcome, not how to achieve said outcome. *"Because it describes the state of the world, declarative configuration does not have to be executed to be understood. Its impact is concretely declared. Since the effects of declarative configuration can be understood before they are executed, declarative configuration is far less error-prone. " --Hightower, Kelsey; Burns, Brendan; Beda, Joe. Kubernetes: Up and Running: Dive into the Future of Infrastructure (Kindle Locations 183-186). Kindle Edition*

#### *To check if a CNF is using the default namespace*: [default_namespace](docs/LIST_OF_TESTS.md#default-namespaces)
> *Namespaces provide a way to segment and isolate cluster resources across multiple applications and users. As a best practice, workloads should be isolated with Namespaces and not use the default namespace. 

#### *To test if mutable tags being used for image versioning(Using Kyverno): latest_tag*: [latest_tag](docs/LIST_OF_TESTS.md#latest-tag)

> *"You should [avoid using the :latest tag](https://kubernetes.io/docs/concepts/containers/images/)
when deploying containers in production as it is harder to track which version of the image 
is running and more difficult to roll back properly."*

#### *To test if the recommended labels are being used to describe resources*: [required_labels](docs/LIST_OF_TESTS.md#require-labels)
> Defining and using labels help identify semantic attributes of your application or Deployment. A common set of labels allows tools to work collaboratively, while describing objects in a common manner that all tools can understand. You should use recommended labels to describe applications in a way that can be queried.


#### *To test if there are versioned tags on all images (using OPA Gatekeeper)*: [versioned_tag](docs/LIST_OF_TESTS.md#versioned-tag)

> *"You should [avoid using the :latest tag](https://kubernetes.io/docs/concepts/containers/images/)
when deploying containers in production as it is harder to track which version of the image 
is running and more difficult to roll back properly."*

#### *To test if there are node ports used in the service configuration*: [nodeport_not_used](docs/LIST_OF_TESTS.md#nodeport-not-used)

> Using node ports ties the CNF to a specific node and therefore makes the CNF less
portable and scalable

#### *To test if there are host ports used in the service configuration*: [hostport_not_used](docs/LIST_OF_TESTS.md#hostport-not-used)

> Using host ports ties the CNF to a specific node and therefore makes the CNF less
portable and scalable

#### *To test if there are any (non-declarative) hardcoded IP addresses or subnet masks in the K8s runtime configuration*: [hardcoded_ip_addresses_in_k8s_runtime_configuration](docs/LIST_OF_TESTS.md#Hardcoded-ip-addresses-in-k8s-runtime-configuration)

> Using a hard coded IP in a CNF's configuration designates *how* (imperative) a CNF should 
achieve a goal, not *what* (declarative) goal the CNF should achieve

#### *To check if a CNF uses K8s secrets*: [secrets_used](docs/LIST_OF_TESTS.md#secrets-used)

> If a CNF uses kubernetes K8s secrets instead of unencrypted environment 
variables or configmaps, there is [less risk of the Secret (and its data) being 
exposed](https://kubernetes.io/docs/concepts/configuration/secret/) during the 
workflow of creating, viewing, and editing Pods

#### *To check if a CNF version uses immutable configmaps*: [immutable_configmap](docs/LIST_OF_TESTS.md#immutable-configmap)

> *"For clusters that extensively use ConfigMaps (at least tens of thousands of unique ConfigMap to Pod mounts), 
[preventing changes](https://kubernetes.io/docs/concepts/configuration/configmap/#configmap-immutable)
to their data has the following advantages:*
- *protects you from accidental (or unwanted) updates that could cause applications outages*
- *improves performance of your cluster by significantly reducing load on kube-apiserver, by 
closing watches for ConfigMaps marked as immutable.*"


## 5g Tests 
####  A 5g core is an important part of the service provider's telecommuncations offering. A cloud native 5g architecture uses immutable infrastructure, declarative configuration, and microservices when creating and hosting 5g cloud native network functions.

#### *To check if the 5g core is resistant to chaos*: [smf_upf_core_validator](docs/LIST_OF_TESTS.md#smf_upf_core_validator)
> *A 5g core's [SMF and UPF CNFs have a hearbeat](https://www.etsi.org/deliver/etsi_ts/123500_123599/123527/15.01.00_60/ts_123527v150100p.pdf), implemented use the PFCP protocol standard, which measures if the connection between the two CNFs is active.  After measure a baseline of the heartbeat a comparison between the baseline and the performance of the heartbeat while running test functions will expose the [cloud native resilience](https://www.cncf.io/blog/2021/09/23/cloud-native-chaos-and-telcos-enforcing-reliability-and-availability-for-telcos/) of the cloud native 5g core.

#### *To check if the 5g core is using 5g authentication*: [suci_enabled](docs/LIST_OF_TESTS.md#suci_enabled)
> *In order to [protect identifying information](https://nickvsnetworking.com/5g-subscriber-identifiers-suci-supi/) from being sent over the network as clear text, 5g cloud native cores should implement [SUPI and SUCI concealment](https://www.etsi.org/deliver/etsi_ts/133500_133599/133514/16.04.00_60/ts_133514v160400p.pdf)  


## RAN Tests 
#### A cloud native radio access network's (RAN) cloud native functions should use immutable infrastructure, declarative configuration, and microservices.  ORAN cloud native functions should adhere to cloud native principles while also complying with the [ORAN alliance's standards](https://www.o-ran.org/blog/o-ran-alliance-introduces-48-new-specifications-released-since-july-2021).

#### *To check if an ORAN compliant RAN is using the e2 3gpp standard*: [oran_e2_connection](docs/LIST_OF_TESTS.md#oran_e2_connection)
> *A near real-time RAN intelligent controler (RIC) uses the [E2 standard](https://wiki.o-ran-sc.org/display/RICP/E2T+Architecture) as an open, interoperable, interface to connect to [RAN-optimizated applications, onboarded as xApps](https://www.5gtechnologyworld.com/how-does-5gs-o-ran-e2-interface-work/). The xApps use platform services available in the near-RT RIC to communicate with the downstream network functions through the E2 interface.

## Platform Tests

#### *To check if the plateform passes K8s Conformance tests*: [k8s-conformance](docs/LIST_OF_TESTS.md#k8s-conformance)
> * A Vendor's Kubernetes Platform should pass [Kubernetes Conformance](https://github.com/kubernetes/community/blob/master/contributors/devel/sig-architecture/conformance-tests.md). This ensures that the platform offering meets the same required APIs, features & interoperability expectations as in open source community versions of K8s. Applications that can operate on a [Certified Kubernetes](https://www.cncf.io/certification/software-conformance/) should be cross-compatible with any other Certified Kubernetes platform.

#### *To check if the plateform is being managed by ClusterAPI*: [clusterapi-enabled](docs/LIST_OF_TESTS.md#clusterapi-enabled)
> * A Kubernetes Platform should leverage [Cluster API](https://cluster-api.sigs.k8s.io/) to ensure that best-practices are followed for both bootstrapping & cluster lifecycle management. Kubernetes is a complex system that relies on several components being configured correctly, maintaining an in-house lifecycle management system for kubernetes is unlikey to meet best practice guideline unless significant resources are deticated to it.

#### *To check if the plateform is using an OCI compliant runtime*: [oci-compliant](docs/LIST_OF_TESTS.md#oci-compliant)
> *The [OCI Initiative](https://opencontainers.org/) was created to ensure that runtimes conform  to both the runtime-spec and image-spec. These two specifications outline how a “filesystem bundle” is unpacked on disk and that the image itself contains sufficient information to launch the application on the target platform. As a best practice, your platform must use an OCI compliant runtime, this ensures that the runtime used is cross-compatible and supports interoperability with other runtimes. This means that workloads can be freely moved to other runtimes and prevents vendor lock in.

#### *To check if workloads are rescheduled on node failure*: [worker-reboot-recovery](docs/LIST_OF_TESTS.md#poc-worker-reboot-recovery)
> *Cloud native systems should be self-healing. To follow cloud-native best practices your platform should be  resiliant and reschedule all workloads when such node failures occur.

#### *To check if the plateform has a default Cluster admin role*: [cluster-admin](docs/LIST_OF_TESTS.md#cluster-admin)
> *Role-based access control (RBAC) is a key security feature in Kubernetes. RBAC can restrict the allowed actions of the various identities in the cluster. Cluster-admin is a built-in high privileged role in Kubernetes. Attackers who have permissions to create bindings and cluster-bindings in the cluster can create a binding to the cluster-admin ClusterRole or to other high privileges roles. As a best practice, a principle of least privilege should be followed and cluster-admin privilege should only be used on an as-needed basis.

#### *Check if the plateform is using insecure ports for the API server*: [Control_plane_hardening](docs/LIST_OF_TESTS.md#control-plane-hardening)
> *The control plane is the core of Kubernetes and gives users the ability to view containers, schedule new Pods, read Secrets, and execute commands in the cluster. Therefore, it should be protected. It is recommended to avoid control plane exposure to the Internet or to an untrusted network and require TLS encryption.

#### *Check if the Dashboard is exposed externally*: [Dashboard exposed](docs/LIST_OF_TESTS.md#dashboard-exposed)
> * If Kubernetes dashboard is exposed externally in Dashboard versions before 2.01, it will allow unauthenticated remote management of the cluster. It's best practice to not expose the K8s Dashboard or any management planes if they're unsecured.

#### *Check if Tiller is being used on the plaform*: [Tiller images](docs/LIST_OF_TESTS.md#tiller-images)
> *Tiller, found in Helm v2, has known security challenges. It requires administrative privileges and acts as a shared resource accessible to any authenticated user. Tiller can lead to privilege escalation as restricted users can impact other users. It is recommend to use Helm v3+ which does not contain Tiller for these reasons

#### *Check if configmaps are encrypted on the plaform*: [Verify if configmaps are encrypted](docs/LIST_OF_TESTS.md#verify-configmaps-encrypted)
> *Configmaps encryption is not enabled by default in kubernetes environment. As configmaps can  contain sensitive information, it is recommended to encrypt these values. For encrypting configmaps in etcd, we are using encryption in rest, this will cause, that there will not be configmaps key value in plain text format anymore in etcd.
