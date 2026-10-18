{{- define "app.service" -}}
{{- $service := .Values.service | default dict -}}
apiVersion: v1
kind: Service
metadata:
  name: {{ template "app.fullname" . }}
  labels:
    {{- include "app.labels" . | nindent 4 }}
  {{- with $service.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  type: {{ $service.type | default "ClusterIP" }}
  ports:
    - name: http
      targetPort: {{ .Values.port }}
      port: {{ .Values.port }}
      protocol: {{ .Values.protocol | default "TCP" }}
  selector:
    {{- include "app.selectorLabels" . | nindent 4 }}
{{- end -}}
