{{- define "app.route" -}}
{{- /* How the route is protected, for the Kyverno policy `require-route-login` */ -}}
{{- $auth := "" -}}
{{- if include "app.oidcEnabled" . -}}
{{- $auth = "gateway" -}}
{{- else -}}
{{- $auth = .Values.route.auth | default "" -}}
{{- end }}
apiVersion: {{ .Values.route.apiVersion | default "gateway.networking.k8s.io/v1" }}
kind: {{ .Values.route.kind | default "HTTPRoute" }}
metadata:
  {{- if or $auth .Values.route.annotations }}
  annotations:
    {{- with $auth }}
    davydehaas.dev/auth: {{ . }}
    {{- end }}
    {{- with .Values.route.annotations }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  {{- end }}
  name: {{ template "app.fullname" . }}
  labels:
    {{- include "app.labels" . | nindent 4 }}
    {{- with .Values.route.labels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
spec:
  {{- with .Values.route.parentRefs }}
  parentRefs:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .Values.route.hostnames }}
  hostnames:
    {{- tpl (toYaml .) $ | nindent 4 }}
  {{- end }}
  rules:
    {{- if .Values.route.additionalRules }}
    {{- tpl (toYaml .Values.route.additionalRules) $ | nindent 4 }}
    {{- end }}
    - backendRefs:
        - name: {{ template "app.fullname" . }}
          port: {{ .Values.port }}
      {{- with .Values.route.filters }}
      filters:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.route.matches }}
      matches:
        {{- toYaml . | nindent 8 }}
      {{- end }}
{{- end -}}
