{{/*
Files of the app from values (`configFiles[].files`): a ConfigMap `<app>-<name>` with a file per key. The
checksum annotation restarts the pod when a file changes, as files mounted with a subPath are not updated in place.
*/}}
{{- define "app.configFiles" -}}
{{- $first := true -}}
{{- range .Values.configFiles }}
{{- if .files }}
{{- if not $first }}
---
{{- end }}
{{- $first = false }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ template "app.fullname" $ }}-{{ .name }}
  labels:
    {{- include "app.selectorLabels" $ | nindent 4 }}
data:
  {{- toYaml .files | nindent 2 }}
{{- end }}
{{- end }}
{{- end -}}

{{- define "app.configChecksums" -}}
{{- range .Values.configFiles }}
{{- if .files }}
checksum/{{ .name }}: {{ toYaml .files | sha256sum }}
{{- end }}
{{- end }}
{{- end -}}
