{{/*
Expand the name of the chart.
*/}}
{{- define "poslite-pam.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "poslite-pam.fullname" -}}
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
{{- define "poslite-pam.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "poslite-pam.labels" -}}
helm.sh/chart: {{ include "poslite-pam.chart" . }}
{{ include "poslite-pam.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "poslite-pam.selectorLabels" -}}
app.kubernetes.io/name: {{ include "poslite-pam.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Service name for pam-tcpconnector
*/}}
{{- define "poslite-pam.tcpconnectorService" -}}
{{- printf "%s-tcpconnector" (include "poslite-pam.fullname" .) }}
{{- end }}

{{/*
Service name for pam-core-webapi
*/}}
{{- define "poslite-pam.coreWebapiService" -}}
{{- printf "%s-core-webapi" (include "poslite-pam.fullname" .) }}
{{- end }}

{{/*
Service name for pam-guard-api
*/}}
{{- define "poslite-pam.guardApiService" -}}
{{- printf "%s-guard-api" (include "poslite-pam.fullname" .) }}
{{- end }}

{{/*
Service name for pam-scraper
*/}}
{{- define "poslite-pam.scraperService" -}}
{{- printf "%s-scraper" (include "poslite-pam.fullname" .) }}
{{- end }}

{{/*
Service name for pam-core-webevents
*/}}
{{- define "poslite-pam.coreWebeventsService" -}}
{{- printf "%s-core-webevents" (include "poslite-pam.fullname" .) }}
{{- end }}

{{/*
Service name for pam-playwright
*/}}
{{- define "poslite-pam.playwrightService" -}}
{{- printf "%s-playwright" (include "poslite-pam.fullname" .) }}
{{- end }}
