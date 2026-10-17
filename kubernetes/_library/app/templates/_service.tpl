{{- define "app.service" -}}
apiVersion: v1
kind: Service
metadata:
  name: {{ template "app.fullname" . }}
  labels:
    {{- include "app.labels" . | nindent 4 }}
spec:
  type: ClusterIP
  ports:
    - name: http
      targetPort: {{ .Values.port }}
      port: {{ .Values.port }}
      protocol: TCP
  selector:
    {{- include "app.selectorLabels" . | nindent 4 }}
{{- end -}}
