# open5gs-smf

![Version: 2.0.7](https://img.shields.io/badge/Version-2.0.7-informational?style=flat-square) ![AppVersion: 2.4.11](https://img.shields.io/badge/AppVersion-2.4.11-informational?style=flat-square)

Helm chart to deploy Open5gs SMF service on Kubernetes.

**Homepage:** <https://github.com/gradiant/openverso-charts>

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| cgiraldo | <cgiraldo@gradiant.org> |  |

## Source Code

* <http://open5gs.org>

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://charts.bitnami.com/bitnami | common | 1.x.x |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` |  |
| args | list | `[]` |  |
| command | list | `[]` |  |
| commonAnnotations | object | `{}` |  |
| commonLabels | object | `{}` |  |
| config.dnsList[0] | string | `"8.8.8.8"` |  |
| config.dnsList[1] | string | `"8.8.4.4"` |  |
| config.dnsList[2] | string | `"2001:4860:4860::8888"` |  |
| config.dnsList[3] | string | `"2001:4860:4860::8844"` |  |
| config.logLevel | string | `"info"` |  |
| config.mtu | int | `1400` |  |
| config.nrf.enabled | bool | `true` |  |
| config.nrf.sbi.hostname | string | `""` |  |
| config.nrf.sbi.port | int | `7777` |  |
| config.pcrf.enabled | bool | `true` |  |
| config.pcrf.frdi.hostname | string | `""` |  |
| config.pcrf.frdi.port | int | `3868` |  |
| config.sbi.advertise | string | `""` |  |
| config.subnetList[0].addr | string | `"10.45.0.1/16"` |  |
| config.subnetList[0].dnn | string | `"internet"` |  |
| config.upf.pfcp.hostname | string | `""` |  |
| config.upf.pfcp.port | int | `8805` |  |
| containerPorts.frdi | int | `3868` |  |
| containerPorts.gtpc | int | `2123` |  |
| containerPorts.gtpu | int | `2152` |  |
| containerPorts.metrics | int | `9090` |  |
| containerPorts.pfcp | int | `8805` |  |
| containerPorts.sbi | int | `7777` |  |
| containerSecurityContext.enabled | bool | `true` |  |
| containerSecurityContext.runAsNonRoot | bool | `true` |  |
| containerSecurityContext.runAsUser | int | `1001` |  |
| customLivenessProbe | object | `{}` |  |
| customOpen5gsConfig | object | `{}` |  |
| customReadinessProbe | object | `{}` |  |
| customStartupProbe | object | `{}` |  |
| extraDeploy | list | `[]` |  |
| extraEnvVars | list | `[]` |  |
| extraEnvVarsCM | string | `""` |  |
| extraEnvVarsSecret | string | `""` |  |
| extraVolumeMounts | list | `[]` |  |
| extraVolumes | list | `[]` |  |
| fullnameOverride | string | `""` |  |
| global.imagePullSecrets | list | `[]` |  |
| global.imageRegistry | string | `""` |  |
| global.storageClass | string | `""` |  |
| hostAliases | list | `[]` |  |
| image.debug | bool | `false` |  |
| image.digest | string | `""` |  |
| image.pullPolicy | string | `"IfNotPresent"` |  |
| image.pullSecrets | list | `[]` |  |
| image.registry | string | `"docker.io"` |  |
| image.repository | string | `"openverso/open5gs"` |  |
| image.tag | string | `"2.4.11"` |  |
| initContainers | list | `[]` |  |
| kubeVersion | string | `""` |  |
| lifecycleHooks | object | `{}` |  |
| livenessProbe.enabled | bool | `true` |  |
| livenessProbe.failureThreshold | int | `5` |  |
| livenessProbe.initialDelaySeconds | int | `600` |  |
| livenessProbe.periodSeconds | int | `10` |  |
| livenessProbe.successThreshold | int | `1` |  |
| livenessProbe.timeoutSeconds | int | `5` |  |
| metrics.enabled | bool | `false` |  |
| metrics.serviceMonitor.additionalLabels | object | `{}` |  |
| metrics.serviceMonitor.enabled | bool | `false` |  |
| metrics.serviceMonitor.honorLabels | bool | `false` |  |
| metrics.serviceMonitor.interval | string | `""` |  |
| metrics.serviceMonitor.metricRelabelings | list | `[]` |  |
| metrics.serviceMonitor.namespace | string | `""` |  |
| metrics.serviceMonitor.relabelings | list | `[]` |  |
| metrics.serviceMonitor.scrapeTimeout | string | `""` |  |
| metrics.serviceScrape.additionalLabels | object | `{}` |  |
| metrics.serviceScrape.enabled | bool | `false` |  |
| metrics.serviceScrape.namespace | string | `""` |  |
| metrics.serviceScrape.scrape_interval | string | `"15s"` |  |
| nameOverride | string | `""` |  |
| namespaceOverride | string | `""` |  |
| nodeAffinityPreset.key | string | `""` |  |
| nodeAffinityPreset.type | string | `""` |  |
| nodeAffinityPreset.values | list | `[]` |  |
| nodeSelector | object | `{}` |  |
| podAffinityPreset | string | `""` |  |
| podAnnotations | object | `{}` |  |
| podAntiAffinityPreset | string | `"soft"` |  |
| podLabels | object | `{}` |  |
| podSecurityContext.enabled | bool | `true` |  |
| podSecurityContext.fsGroup | int | `1001` |  |
| priorityClassName | string | `""` |  |
| readinessProbe.enabled | bool | `true` |  |
| readinessProbe.failureThreshold | int | `5` |  |
| readinessProbe.initialDelaySeconds | int | `30` |  |
| readinessProbe.periodSeconds | int | `5` |  |
| readinessProbe.successThreshold | int | `1` |  |
| readinessProbe.timeoutSeconds | int | `1` |  |
| replicaCount | int | `1` |  |
| resources.limits | object | `{}` |  |
| resources.requests | object | `{}` |  |
| schedulerName | string | `""` |  |
| serviceAccount.annotations | object | `{}` |  |
| serviceAccount.automountServiceAccountToken | bool | `true` |  |
| serviceAccount.create | bool | `false` |  |
| serviceAccount.name | string | `""` |  |
| services.frdi.annotations | object | `{}` |  |
| services.frdi.clusterIP | string | `""` |  |
| services.frdi.externalTrafficPolicy | string | `"Cluster"` |  |
| services.frdi.extraPorts | list | `[]` |  |
| services.frdi.loadBalancerIP | string | `""` |  |
| services.frdi.loadBalancerSourceRanges | list | `[]` |  |
| services.frdi.nodePorts.frdi | string | `""` |  |
| services.frdi.ports.frdi | int | `3868` |  |
| services.frdi.sessionAffinity | string | `"None"` |  |
| services.frdi.sessionAffinityConfig | object | `{}` |  |
| services.frdi.type | string | `"ClusterIP"` |  |
| services.gtpc.annotations | object | `{}` |  |
| services.gtpc.clusterIP | string | `""` |  |
| services.gtpc.externalTrafficPolicy | string | `"Cluster"` |  |
| services.gtpc.extraPorts | list | `[]` |  |
| services.gtpc.loadBalancerIP | string | `""` |  |
| services.gtpc.loadBalancerSourceRanges | list | `[]` |  |
| services.gtpc.nodePorts.gtpc | string | `""` |  |
| services.gtpc.ports.gtpc | int | `2123` |  |
| services.gtpc.sessionAffinity | string | `"None"` |  |
| services.gtpc.sessionAffinityConfig | object | `{}` |  |
| services.gtpc.type | string | `"ClusterIP"` |  |
| services.gtpu.annotations | object | `{}` |  |
| services.gtpu.clusterIP | string | `""` |  |
| services.gtpu.externalTrafficPolicy | string | `"Cluster"` |  |
| services.gtpu.extraPorts | list | `[]` |  |
| services.gtpu.loadBalancerIP | string | `""` |  |
| services.gtpu.loadBalancerSourceRanges | list | `[]` |  |
| services.gtpu.nodePorts.gtpu | string | `""` |  |
| services.gtpu.ports.gtpu | int | `2152` |  |
| services.gtpu.sessionAffinity | string | `"None"` |  |
| services.gtpu.sessionAffinityConfig | object | `{}` |  |
| services.gtpu.type | string | `"ClusterIP"` |  |
| services.metrics.annotations."prometheus.io/path" | string | `"/metrics"` |  |
| services.metrics.clusterIP | string | `""` |  |
| services.metrics.externalTrafficPolicy | string | `"Cluster"` |  |
| services.metrics.extraPorts | list | `[]` |  |
| services.metrics.loadBalancerIP | string | `""` |  |
| services.metrics.loadBalancerSourceRanges | list | `[]` |  |
| services.metrics.nodePorts.metrics | string | `""` |  |
| services.metrics.ports.metrics | int | `9090` |  |
| services.metrics.sessionAffinity | string | `"None"` |  |
| services.metrics.sessionAffinityConfig | object | `{}` |  |
| services.metrics.type | string | `"ClusterIP"` |  |
| services.pfcp.annotations | object | `{}` |  |
| services.pfcp.clusterIP | string | `""` |  |
| services.pfcp.externalTrafficPolicy | string | `"Cluster"` |  |
| services.pfcp.extraPorts | list | `[]` |  |
| services.pfcp.loadBalancerIP | string | `""` |  |
| services.pfcp.loadBalancerSourceRanges | list | `[]` |  |
| services.pfcp.nodePorts.pfcp | string | `""` |  |
| services.pfcp.ports.pfcp | int | `8805` |  |
| services.pfcp.sessionAffinity | string | `"None"` |  |
| services.pfcp.sessionAffinityConfig | object | `{}` |  |
| services.pfcp.type | string | `"ClusterIP"` |  |
| services.sbi.annotations | object | `{}` |  |
| services.sbi.clusterIP | string | `""` |  |
| services.sbi.externalTrafficPolicy | string | `"Cluster"` |  |
| services.sbi.extraPorts | list | `[]` |  |
| services.sbi.loadBalancerIP | string | `""` |  |
| services.sbi.loadBalancerSourceRanges | list | `[]` |  |
| services.sbi.nodePorts.sbi | string | `""` |  |
| services.sbi.ports.sbi | int | `7777` |  |
| services.sbi.sessionAffinity | string | `"None"` |  |
| services.sbi.sessionAffinityConfig | object | `{}` |  |
| services.sbi.type | string | `"ClusterIP"` |  |
| sessionAffinity | string | `"None"` |  |
| sidecars | list | `[]` |  |
| startupProbe.enabled | bool | `false` |  |
| startupProbe.failureThreshold | int | `5` |  |
| startupProbe.initialDelaySeconds | int | `600` |  |
| startupProbe.path | string | `"/"` |  |
| startupProbe.periodSeconds | int | `10` |  |
| startupProbe.successThreshold | int | `1` |  |
| startupProbe.timeoutSeconds | int | `5` |  |
| tolerations | list | `[]` |  |
| topologySpreadConstraints | list | `[]` |  |
| updateStrategy.type | string | `"RollingUpdate"` |  |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.11.0](https://github.com/norwoodj/helm-docs/releases/v1.11.0)
