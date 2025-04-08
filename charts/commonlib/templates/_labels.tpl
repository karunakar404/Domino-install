{{/* vim: set filetype=mustache: */}}

{{/*
Prints the standard labels frequently used in metadata.
*/}}
{{- define "common.labels.standard" -}}
app.kubernetes.io/name: {{ include "common.name" . }}
helm.sh/chart: {{ include "common.chart" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Prints the labels frequently used in selector clauses.
*/}}
{{- define "common.labels.selector" -}}
app.kubernetes.io/name: {{ include "common.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Prints a label for marking the different roles that pieces may play in an
application. Input should be a string representation of the component name.
*/}}
{{- define "common.labels.component" -}}
app.kubernetes.io/component: {{ . }}
{{- end -}}
