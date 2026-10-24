{{/*
A second route on the hostnames of the app for the paths in `oidc.bypassPaths`, without the OIDC policy. The more
specific path wins over the main route, so these paths skip the login and stay protected by the app itself.
*/}}
{{- define "app.bypassRoute" -}}
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  annotations:
    davydehaas.dev/auth: bypass
  name: {{ template "app.fullname" . }}-bypass
  labels:
    {{- include "app.labels" . | nindent 4 }}
spec:
  {{- with .Values.route.parentRefs }}
  parentRefs:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  hostnames:
    {{- toYaml .Values.route.hostnames | nindent 4 }}
  rules:
    - matches:
        {{- range .Values.oidc.bypassPaths }}
        - path:
            type: PathPrefix
            value: {{ . }}
        {{- end }}
      backendRefs:
        - name: {{ template "app.fullname" . }}
          port: {{ .Values.port }}
{{- end -}}
