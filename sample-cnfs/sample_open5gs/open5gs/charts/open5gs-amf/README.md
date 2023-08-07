# open5gs-amf

![Version: 2.0.10](https://img.shields.io/badge/Version-2.0.10-informational?style=flat-square) ![AppVersion: 2.4.11](https://img.shields.io/badge/AppVersion-2.4.11-informational?style=flat-square)

Helm chart to deploy Open5gs AMF service on Kubernetes.

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
| config.guamiList[0].amf_id.region | int | `2` |  |
| config.guamiList[0].amf_id.set | int | `1` |  |
| config.guamiList[0].plmn_id.mcc | string | `"999"` |  |
| config.guamiList[0].plmn_id.mnc | string | `"70"` |  |
| config.logLevel | string | `"info"` |  |
| config.networkName | string | `"Gradiant"` |  |
| config.nrf.sbi.hostname | string | `""` |  |
| config.nrf.sbi.port | int | `7777` |  |
| config.plmnList[0].plmn_id.mcc | string | `"999"` |  |
| config.plmnList[0].plmn_id.mnc | string | `"70"` |  |
| config.plmnList[0].s_nssai[0].sd | string | `"0x111111"` |  |
| config.plmnList[0].s_nssai[0].sst | int | `1` |  |
| config.sbi.advertise | string | `""` |  |
| config.taiList[0].plmn_id.mcc | string | `"999"` |  |
| config.taiList[0].plmn_id.mnc | string | `"70"` |  |
| config.taiList[0].tac[0] | int | `1` |  |
| config.taiList[0].tac[1] | int | `2` |  |
| config.taiList[0].tac[2] | int | `3` |  |
| containerPorts.metrics | int | `9090` |  |
| containerPorts.ngap | int | `38412` |  |
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
| services.ngap.annotations | object | `{}` |  |
| services.ngap.clusterIP | string | `""` |  |
| services.ngap.externalTrafficPolicy | string | `"Cluster"` |  |
| services.ngap.extraPorts | list | `[]` |  |
| services.ngap.loadBalancerIP | string | `""` |  |
| services.ngap.loadBalancerSourceRanges | list | `[]` |  |
| services.ngap.nodePorts.ngap | string | `""` |  |
| services.ngap.ports.ngap | int | `38412` |  |
| services.ngap.sessionAffinity | string | `"None"` |  |
| services.ngap.sessionAffinityConfig | object | `{}` |  |
| services.ngap.type | string | `"ClusterIP"` |  |
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
