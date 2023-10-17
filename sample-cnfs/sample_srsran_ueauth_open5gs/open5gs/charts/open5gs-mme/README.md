# open5gs-mme

![Version: 2.0.5](https://img.shields.io/badge/Version-2.0.5-informational?style=flat-square) ![AppVersion: 2.4.11](https://img.shields.io/badge/AppVersion-2.4.11-informational?style=flat-square)

Helm chart to deploy Open5gs MME service on Kubernetes.

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
| config.gummeiList[0].mme_code | int | `1` |  |
| config.gummeiList[0].mme_gid | int | `2` |  |
| config.gummeiList[0].plmn_id.mcc | string | `"999"` |  |
| config.gummeiList[0].plmn_id.mnc | string | `"70"` |  |
| config.hss.frdi.hostname | string | `""` |  |
| config.hss.frdi.port | int | `3868` |  |
| config.logLevel | string | `"info"` |  |
| config.networkName | string | `"Gradiant"` |  |
| config.sgwc.gtpc.hostname | string | `""` |  |
| config.sgwc.gtpc.port | int | `2123` |  |
| config.smf.gtpc.hostname | string | `""` |  |
| config.smf.gtpc.port | int | `2123` |  |
| config.taiList[0].plmn_id.mcc | string | `"999"` |  |
| config.taiList[0].plmn_id.mnc | string | `"70"` |  |
| config.taiList[0].tac[0] | int | `0` |  |
| config.taiList[0].tac[1] | int | `1` |  |
| config.taiList[0].tac[2] | int | `2` |  |
| containerPorts.frdi | int | `3868` |  |
| containerPorts.gtpc | int | `2123` |  |
| containerPorts.s1ap | int | `36412` |  |
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
| services.s1ap.annotations | object | `{}` |  |
| services.s1ap.clusterIP | string | `""` |  |
| services.s1ap.externalTrafficPolicy | string | `"Cluster"` |  |
| services.s1ap.extraPorts | list | `[]` |  |
| services.s1ap.loadBalancerIP | string | `""` |  |
| services.s1ap.loadBalancerSourceRanges | list | `[]` |  |
| services.s1ap.nodePorts.s1ap | string | `""` |  |
| services.s1ap.ports.s1ap | int | `36412` |  |
| services.s1ap.sessionAffinity | string | `"None"` |  |
| services.s1ap.sessionAffinityConfig | object | `{}` |  |
| services.s1ap.type | string | `"ClusterIP"` |  |
| sessionAffinity | string | `"None"` |  |
| sidecars | list | `[]` |  |
| tolerations | list | `[]` |  |
| topologySpreadConstraints | list | `[]` |  |
| updateStrategy.type | string | `"RollingUpdate"` |  |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.11.0](https://github.com/norwoodj/helm-docs/releases/v1.11.0)
