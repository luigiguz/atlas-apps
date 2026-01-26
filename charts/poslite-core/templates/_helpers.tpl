{{/*
Expand the name of the chart.
*/}}
{{- define "poslite-core.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "poslite-core.fullname" -}}
{{- if .Values.nameOverride }}
{{- .Values.nameOverride | trunc 63 | trimSuffix "-" }}
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
{{- define "poslite-core.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "poslite-core.labels" -}}
helm.sh/chart: {{ include "poslite-core.chart" . }}
{{ include "poslite-core.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "poslite-core.selectorLabels" -}}
app.kubernetes.io/name: {{ include "poslite-core.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Image reference
*/}}
{{- define "poslite-core.image" -}}
{{- printf "%s/%s/%s" .Values.imageRegistry .Values.imageRepository .imageRepository }}:{{ .imageTag }}
{{- end }}

{{/*
Service name for core-webapi
*/}}
{{- define "poslite-core.webapiService" -}}
{{- printf "%s-webapi" (include "poslite-core.fullname" .) }}
{{- end }}
