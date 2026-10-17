{{- define "app.statefulset" -}}
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: {{ template "app.fullname" . }}
  labels:
    {{- include "app.labels" . | nindent 4 }}
spec:
  revisionHistoryLimit: 0
  replicas: {{ .Values.replicas | default 1 }}
  selector:
    matchLabels:
      {{- include "app.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "app.selectorLabels" . | nindent 8 }}
    spec:
      securityContext: {{ toYaml (.Values.podSecurityContext | default dict) | nindent 8 }}
      containers:
        - name: {{ template "app.name" . }}
          image: "{{ .Values.image.registry }}/{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          env:
            {{- range $name, $value := merge (deepCopy (.Values.env | default dict)) (dict "TZ" "Europe/Amsterdam") }}
            - name: {{ $name }}
              value: {{ $value | toString | quote }}
            {{- end }}
          ports:
            - name: http
              containerPort: {{ .Values.port }}
              protocol: TCP
          resources: {{ toYaml (.Values.resources | default dict) | nindent 12 }}
          securityContext: {{ toYaml (.Values.securityContext | default dict) | nindent 12 }}
          {{- $probe := .Values.probe | default (dict "httpGet" (dict "path" "/" "port" "http")) }}
          # The first start of an app with a new database runs its migrations, which takes minutes on NFS.
          # The liveness probe only starts once this one succeeds (up to 15 minutes), instead of killing the app halfway.
          startupProbe: {{ toYaml (merge (deepCopy $probe) (dict "periodSeconds" 10 "failureThreshold" 90)) | nindent 12 }}
          livenessProbe: {{ toYaml $probe | nindent 12 }}
          readinessProbe: {{ toYaml $probe | nindent 12 }}
          volumeMounts:
            {{- if .Values.persistence }}
            - mountPath: {{ .Values.persistence.mountPath | default "/config" }}
              name: config
            {{- end }}
            {{- with (.Values.media | default dict).mounts }}
            # Mounted at the paths of the home-server containers, so a restored configuration keeps working
            {{- range . }}
            - mountPath: {{ .mountPath }}
              name: media
              subPath: {{ .subPath }}
            {{- end }}
            {{- end }}
      volumes:
        {{- if .Values.persistence }}
        - name: config
          persistentVolumeClaim:
            claimName: {{ template "app.fullname" . }}-config
        {{- end }}
        {{- if (.Values.media | default dict).mounts }}
        - name: media
          persistentVolumeClaim:
            claimName: {{ .Values.media.claimName }}
        {{- end }}
{{- end -}}
