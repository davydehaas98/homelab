{{/*
Extra hostnames of the app (`route.aliases`) that redirect to its first hostname. A separate route with
a permanent redirect, so the login (cookies and callback of the first hostname) works for every name.
*/}}
{{- define "app.aliasRoute" -}}
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: {{ template "app.fullname" . }}-aliases
  labels:
    {{- include "app.labels" . | nindent 4 }}
spec:
  {{- with .Values.route.parentRefs }}
  parentRefs:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  hostnames:
    {{- toYaml .Values.route.aliases | nindent 4 }}
  rules:
    - filters:
        - type: RequestRedirect
          requestRedirect:
            scheme: https
            hostname: {{ first .Values.route.hostnames }}
            statusCode: 301
{{- end -}}
