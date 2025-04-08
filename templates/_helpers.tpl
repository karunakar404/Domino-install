{{/* vim: set filetype=mustache: */}}
{{/* Default macros are in commonlib, chart-specific ones go here */}}

{{/*
Return the controller service account name.
*/}}
{{- define "po.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default "platform-operator" .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Return the namespace
*/}}
{{- define "po.namespace" -}}
{{- .Release.Namespace -}}
{{- end -}}

{{/*
Return the self-signed issuer name
*/}}
{{- define "po.certmanager.selfSignedIssuer" -}}
{{ include "common.fullname" . }}-selfsigned-issuer
{{- end }}

{{/*
Return the name of the webhook service
*/}}
{{- define "po.webhook.service" -}}
{{ include "common.fullname" . }}-webhook-service
{{- end }}

{{/* 
Return the name fo the self-signed cert
*/}}
{{- define "po.certmanager.selfSignedCert" -}}
{{ include "common.fullname" . }}-serving-cert
{{- end }}

{{/*
Return the name of the webhook secret
*/}}
{{- define "po.webhook.secret" -}}
{{ include "po.webhook.service" . }}-cert
{{- end }}

{{/*
Return the webhook annotations
*/}}
{{- define "po.webhook.annotations" -}}
{{- if .Values.webhook.certManager -}}
cert-manager.io/inject-ca-from: {{ .Release.Namespace }}/{{ include "po.certmanager.selfSignedCert" . }}
{{- end -}}
{{- end }}
