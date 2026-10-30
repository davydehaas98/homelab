{{/*
The app's volume, a claim named `<app>-config`. The claim gets a volume from `persistence.storageClass` (the default
StorageClass when unset), or the static ZFS volume `persistence.volumeName` (kubernetes/storage/zfs-localpv).
*/}}
{{- define "app.volume" -}}
{{- $name := include "app.fullname" . -}}
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: {{ $name }}-config
  labels:
    {{- include "app.selectorLabels" . | nindent 4 }}
    {{- with .Values.persistence.labels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
spec:
  accessModes:
    - ReadWriteOnce
  {{- with .Values.persistence.storageClass }}
  storageClassName: {{ . }}
  {{- end }}
  {{- with .Values.persistence.volumeName }}
  volumeName: {{ . }}
  {{- end }}
  resources:
    requests:
      storage: {{ .Values.persistence.size }}
{{- end -}}
