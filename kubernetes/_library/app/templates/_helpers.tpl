{{- define "app.name" -}}
{{- .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "app.fullname" -}}
{{- if contains .Chart.Name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "app.selectorLabels" -}}
app.kubernetes.io/name: {{ template "app.name" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/part-of: {{ .Chart.Name | quote }}
{{- end -}}

{{- define "app.labels" -}}
app.kubernetes.io/name: {{ template "app.name" . }}
helm.sh/chart: {{ include "app.chart" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Values.image.tag | quote }}
app.kubernetes.io/part-of: {{ .Chart.Name | quote }}
{{- end -}}

{{/* Renders every resource of an app. An app chart only needs `{{ include "app.resources" . }}` */}}
{{- define "app.resources" -}}
{{- if .Values.persistence }}
{{ include "app.volume" . }}
---
{{- end }}
{{ include "app.statefulset" . }}
---
{{ include "app.service" . }}
{{- if (.Values.route | default dict).enabled }}
---
{{ include "app.route" . }}
{{- if (.Values.oidc | default dict).enabled }}
---
{{ include "app.securityPolicy" . }}
{{- end }}
{{- if .Values.route.aliases }}
---
{{ include "app.aliasRoute" . }}
{{- end }}
{{- end }}
{{- end -}}
