{{/*
Files of an entry of `configFiles`, as JSON: its `files` (a map of file name to content) plus the files of the app
chart that match its `glob` (relative to the chart, not recursive), under their base name.
*/}}
{{- define "app.configData" -}}
{{- $data := deepCopy (.entry.files | default dict) -}}
{{- if .entry.glob -}}
{{- range $path, $bytes := .root.Files.Glob .entry.glob -}}
{{- $_ := set $data (base $path) (toString $bytes) -}}
{{- end -}}
{{- end -}}
{{- toJson $data -}}
{{- end -}}

{{/*
Files of the app (`configFiles[].files` and `configFiles[].glob`): a ConfigMap `<app>-<name>` with a file per key. The
checksum annotation restarts the pod when a file changes, as files mounted with a subPath are not updated in place.
*/}}
{{- define "app.configFiles" -}}
{{- $first := true -}}
{{- range .Values.configFiles }}
{{- $data := include "app.configData" (dict "root" $ "entry" .) | fromJson }}
{{- if $data }}
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
  {{- toYaml $data | nindent 2 }}
{{- end }}
{{- end }}
{{- end -}}

{{- define "app.configChecksums" -}}
{{- range .Values.configFiles }}
{{- $data := include "app.configData" (dict "root" $ "entry" .) | fromJson }}
{{- if $data }}
checksum/{{ .name }}: {{ toYaml $data | sha256sum }}
{{- end }}
{{- end }}
{{- end -}}
