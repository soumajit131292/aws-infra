{{- define "accesshub.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "accesshub.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name (include "accesshub.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "accesshub.labels" -}}
app.kubernetes.io/name: {{ include "accesshub.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | quote }}
{{- end -}}

{{- define "accesshub.dbSecretName" -}}
{{- if .Values.global.database.existingSecret -}}
{{- .Values.global.database.existingSecret -}}
{{- else if .Values.externalSecret.enabled -}}
{{- .Values.externalSecret.target.name -}}
{{- else -}}
{{- "" -}}
{{- end -}}
{{- end -}}

{{- define "accesshub.dbConfigMapName" -}}
{{- if .Values.global.database.existingConfigMap -}}
{{- .Values.global.database.existingConfigMap -}}
{{- else if .Values.global.database.configMap.create -}}
{{- .Values.global.database.configMap.name -}}
{{- else -}}
{{- "" -}}
{{- end -}}
{{- end -}}

{{- define "accesshub.runtimeSecretName" -}}
{{- if .Values.global.runtime.existingSecret -}}
{{- .Values.global.runtime.existingSecret -}}
{{- else -}}
{{- "" -}}
{{- end -}}
{{- end -}}

{{- define "accesshub.image" -}}
{{- $root := .root -}}
{{- $svc := .svc -}}
{{- $name := .name -}}
{{- $digest := required (printf "services.%s.digest is required" $name) $svc.digest -}}
{{- if $root.Values.global.imageRegistry -}}
{{- printf "%s/%s@%s" (trimSuffix "/" $root.Values.global.imageRegistry) $svc.repository $digest -}}
{{- else -}}
{{- printf "%s@%s" $svc.repository $digest -}}
{{- end -}}
{{- end -}}

{{- define "accesshub.validDigest" -}}
{{- $digest := default "" .digest -}}
{{- if regexMatch "^sha256:[A-Fa-f0-9]{64}$" $digest -}}
true
{{- else -}}
false
{{- end -}}
{{- end -}}

{{- define "accesshub.deployService" -}}
{{- $enabled := default false .enabled -}}
{{- $valid := eq (trim (include "accesshub.validDigest" (dict "digest" .digest))) "true" -}}
{{- if and $enabled $valid -}}
true
{{- else -}}
false
{{- end -}}
{{- end -}}
