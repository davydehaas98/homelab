{{/*
A StatefulSet by default: it stops the old pod before it starts the new one, so a disk that only one pod may mount is
never mounted twice. An app without a volume can set `kind: Deployment` for rolling updates.
*/}}
{{- define "app.workload" -}}
{{- $kind := .Values.kind | default "StatefulSet" -}}
{{- if and (eq $kind "Deployment") .Values.persistence }}
{{- fail "kind: Deployment needs an app without persistence, as a new pod would start before the old one stops" }}
{{- end -}}
apiVersion: apps/v1
kind: {{ $kind }}
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
      securityContext: {{ toYaml (merge (deepCopy (.Values.podSecurityContext | default dict)) (dict "seccompProfile" (dict "type" "RuntimeDefault"))) | nindent 8 }}
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
          securityContext: {{ toYaml (merge (deepCopy (.Values.securityContext | default dict)) (dict "allowPrivilegeEscalation" false)) | nindent 12 }}
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
            {{- range $key := ($f.keys | default (keys (include "app.configData" (dict "root" $ "entry" $f) | fromJson) | sortAlpha)) }}
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
            {{- with .defaultMode }}
            defaultMode: {{ . }}
            {{- end }}
          {{- else }}
          configMap:
            name: {{ template "app.fullname" $ }}-{{ .name }}
            {{- with .defaultMode }}
            defaultMode: {{ . }}
            {{- end }}
          {{- end }}
        {{- end }}
{{- end -}}
