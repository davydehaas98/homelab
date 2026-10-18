{{/*
The app's volume, a claim named `<app>-config`. With `persistence.iscsi` it is an iSCSI LUN on the home
server (yggdrasil), which the node mounts as a local ext4 disk so SQLite locking works (see
kubernetes/media-server/media-server/README.md). Without it, the claim gets a volume from `persistence.storageClass`
(the default StorageClass, NFS, when unset), which is fine for apps without SQLite.
*/}}
{{- define "app.volume" -}}
{{- $name := include "app.fullname" . -}}
{{- with .Values.persistence.iscsi }}
apiVersion: v1
kind: PersistentVolume
metadata:
  name: {{ $.Release.Namespace }}-{{ $name }}-config
spec:
  capacity:
    storage: {{ $.Values.persistence.size }}
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: ""
  # Mounted by the democratic-csi driver `node-manual` (kubernetes/storage/democratic-csi), as the kubelet
  # of Talos cannot run iscsiadm for a plain `iscsi` volume
  csi:
    driver: org.democratic-csi.node-manual
    fsType: ext4
    readOnly: false
    volumeHandle: {{ $.Release.Namespace }}-{{ $name }}-config
    volumeAttributes:
      portal: {{ .targetPortal | quote }}
      iqn: {{ .iqn | quote }}
      lun: {{ .lun | quote }}
      node_attach_driver: iscsi
      provisioner_driver: node-manual
  claimRef:
    namespace: {{ $.Release.Namespace }}
    name: {{ $name }}-config
---
{{- end }}
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
  {{- if .Values.persistence.iscsi }}
  storageClassName: ""
  volumeName: {{ .Release.Namespace }}-{{ $name }}-config
  {{- else if .Values.persistence.storageClass }}
  storageClassName: {{ .Values.persistence.storageClass }}
  {{- end }}
  resources:
    requests:
      storage: {{ .Values.persistence.size }}
{{- end -}}
