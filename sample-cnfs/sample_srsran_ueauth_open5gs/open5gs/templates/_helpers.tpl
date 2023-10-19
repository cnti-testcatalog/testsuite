{{/*
Return the proper Open5gs image name
*/}}
{{- define "open5gs.populate.image" -}}
{{- include "common.images.image" (dict "imageRoot" .Values.populate.image "global" .Values.global ) -}}
{{- end -}}

{{/*
Return the proper Docker Image Registry Secret Names
*/}}
{{- define "open5gs.populate.imagePullSecrets" -}}
{{- include "common.images.pullSecrets" (dict "images" (list .Values.populate.image ) "global" .Values.global) -}}
{{- end -}}