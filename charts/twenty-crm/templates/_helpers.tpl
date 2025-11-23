{{/*
Expand the name of the chart.
*/}}
{{- define "twenty-helm.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "twenty-helm.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "twenty-helm.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "twenty-helm.labels" -}}
helm.sh/chart: {{ include "twenty-helm.chart" . }}
{{ include "twenty-helm.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "twenty-helm.selectorLabels" -}}
app.kubernetes.io/name: {{ include "twenty-helm.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "twenty-helm.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "twenty-helm.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Database URL
*/}}
{{- define "twenty-helm.databaseUrl" -}}
{{- if .Values.externalDatabase.enabled -}}
postgres://{{ .Values.externalDatabase.username }}:{{ .Values.externalDatabase.password }}@{{ .Values.externalDatabase.host }}:{{ .Values.externalDatabase.port }}/{{ .Values.externalDatabase.database }}
{{- else if .Values.zalandoPostgresql.enabled -}}
postgres://postgres:$(POSTGRES_PASSWORD)@{{ .Values.zalandoPostgresql.clusterName }}:5432/{{ .Values.zalandoPostgresql.database }}
{{- else if .Values.postgres.enabled -}}
postgres://postgres:postgres@{{ include "twenty-helm.fullname" . }}-db:5432/default
{{- else -}}
postgres://postgres:postgres@twentycrm-db.twentycrm.svc.cluster.local/default
{{- end -}}
{{- end }}

{{/*
Redis URL
*/}}
{{- define "twenty-helm.redisUrl" -}}
{{- if .Values.externalRedis.enabled -}}
{{- if .Values.externalRedis.password -}}
redis://:{{ .Values.externalRedis.password }}@{{ .Values.externalRedis.host }}:{{ .Values.externalRedis.port }}
{{- else -}}
redis://{{ .Values.externalRedis.host }}:{{ .Values.externalRedis.port }}
{{- end -}}
{{- else if .Values.redis.enabled -}}
{{- if .Values.redis.auth.enabled -}}
redis://:{{ .Values.redis.auth.password }}@{{ include "twenty-helm.name" . }}-redis-master:6379
{{- else -}}
redis://{{ include "twenty-helm.fullname" . }}-redis-master:6379
{{- end -}}
{{- else -}}
redis://twentycrm-redis.twentycrm.svc.cluster.local:6379
{{- end -}}
{{- end }}