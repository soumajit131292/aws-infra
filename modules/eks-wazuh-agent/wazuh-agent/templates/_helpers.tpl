{{- define "wazuh-agent.name" -}}
{{- .Chart.Name -}}
{{- end -}}

{{- define "wazuh-agent.labels" -}}
app.kubernetes.io/name: {{ include "wazuh-agent.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
{{- end -}}

{{- define "wazuh-agent.selectorLabels" -}}
app.kubernetes.io/name: {{ include "wazuh-agent.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "wazuh-agent.image" -}}
{{- printf "%s/%s:%s" .Values.image.registry .Values.image.repository .Values.image.tag -}}
{{- end -}}
