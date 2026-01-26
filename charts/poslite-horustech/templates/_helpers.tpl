{{/*
Expand the name of the chart.
*/}}
{{- define "poslite-horustech.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "poslite-horustech.fullname" -}}
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
{{- define "poslite-horustech.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "poslite-horustech.labels" -}}
helm.sh/chart: {{ include "poslite-horustech.chart" . }}
{{ include "poslite-horustech.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "poslite-horustech.selectorLabels" -}}
app.kubernetes.io/name: {{ include "poslite-horustech.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Service name for horustech-webapi
*/}}
{{- define "poslite-horustech.webapiService" -}}
{{- printf "%s-webapi" (include "poslite-horustech.fullname" .) }}
{{- end }}

{{/*
Service name for horustech-core-webapi
*/}}
{{- define "poslite-horustech.coreWebapiService" -}}
{{- printf "%s-core-webapi" (include "poslite-horustech.fullname" .) }}
{{- end }}

{{/*
Service name for horustech-guard-api
*/}}
{{- define "poslite-horustech.guardApiService" -}}
{{- printf "%s-guard-api" (include "poslite-horustech.fullname" .) }}
{{- end }}

{{/*
Service name for horustech-core-webevents
*/}}
{{- define "poslite-horustech.coreWebeventsService" -}}
{{- printf "%s-core-webevents" (include "poslite-horustech.fullname" .) }}
{{- end }}
