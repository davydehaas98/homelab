{{/*
A second route for the paths in `oidc.bypassPaths`, without the OIDC policy, which stay protected by the app itself. On
the hostnames of the app the more specific path wins over the main route, so these paths skip the login. With
`oidc.privateHostname` the route is on that name on the private gateway instead, so the internet cannot reach the paths
and they go through the login on the public name.
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
  {{- with .Values.oidc.privateHostname }}
  parentRefs:
    - name: envoy-gateway-private
      namespace: envoy-gateway
      sectionName: web-https-lan
  hostnames:
    - {{ . }}
  {{- else }}
  {{- with .Values.route.parentRefs }}
  parentRefs:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  hostnames:
    {{- toYaml .Values.route.hostnames | nindent 4 }}
  {{- end }}
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
