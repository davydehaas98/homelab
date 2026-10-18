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
      {{- with (include "app.configChecksums" . | trim) }}
      annotations:
        {{- . | nindent 8 }}
      {{- end }}
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
          {{- with .Values.envFrom }}
          envFrom:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          ports:
            - name: http
              containerPort: {{ .Values.port }}
              protocol: {{ .Values.protocol | default "TCP" }}
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
              {{- if .readOnly }}
              readOnly: true
              {{- end }}
            {{- end }}
            {{- end }}
            {{- range .Values.emptyDirs }}
            - mountPath: {{ .mountPath }}
              name: {{ .name }}
            {{- end }}
            {{- range $f := .Values.configFiles }}
            {{- range $key := ($f.keys | default (keys ($f.files | default dict) | sortAlpha)) }}
            - mountPath: {{ $f.mountPath }}/{{ $key }}
              name: files-{{ $f.name }}
              subPath: {{ $key }}
              readOnly: true
            {{- end }}
            {{- end }}
            {{- with .Values.backups }}
            # After the volume of /config, so the backups of the app stay outside its database volume
            - mountPath: {{ .mountPath | default "/config/Backups" }}
              name: backups
              subPath: {{ .subPath }}
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
        {{- with .Values.backups }}
        - name: backups
          persistentVolumeClaim:
            claimName: {{ .claimName }}
        {{- end }}
        {{- range .Values.emptyDirs }}
        - name: {{ .name }}
          emptyDir: {{ toYaml (omit . "name" "mountPath") | nindent 12 }}
        {{- end }}
        {{- range .Values.configFiles }}
        - name: files-{{ .name }}
          {{- if .secret }}
          secret:
            secretName: {{ .secret }}
          {{- else }}
          configMap:
            name: {{ template "app.fullname" $ }}-{{ .name }}
          {{- end }}
        {{- end }}
{{- end -}}
