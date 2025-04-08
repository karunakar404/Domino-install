{{/* vim: set filetype=mustache: */}}

{{/*
Renders full specification for an Ingress object.

If no host is given, then this will just create a path-based routing rule. If a
tls secret is listed, then a tls-termination section will be rendered; a host
name MUST be provided as well. If you define ingress `paths` instead of `path`,
then multiple rules will be created for each path. You MUST define one of these
values.

You can override the default service name and port by adding the values
"overrideName" and "overridePort", respectively, to the context passed to this
macro.

Expected values: `ingress.path` or `ingress.paths`
Optional values: `ingress.annotations`, `ingress.hosts`, `ingress.host` and `ingress.tlsSecret`
*/}}
{{- define "common.ingress.fullspec" -}}
{{- if not .Values.ingress.paths -}}
{{- $_ := required ".Values.ingress.paths or .Values.ingress.path is required!" .Values.ingress.path -}}
{{- end -}}

{{- $kubeVersion := .Capabilities.KubeVersion.GitVersion }}
{{- $ingressPaths := or .Values.ingress.paths (compact (list .Values.ingress.path)) -}}
{{- $ingressHosts := or .Values.ingress.hosts (compact (list .Values.ingress.host)) -}}
{{- $serviceName := default (include "common.fullname" .) .overrideName -}}
{{- $servicePort := default "http" .overridePort -}}
{{  $service := dict "name" $serviceName "port" $servicePort "kubeVersion" $kubeVersion }}

ingressClassName: {{ required ".Values.ingress.ingressClassName is required" .Values.ingress.ingressClassName }}
{{- with .Values.ingress.tlsSecret }}
tls:
- hosts:
  {{- if not $ingressHosts -}}
  {{- fail ".Values.ingress.host or .hosts is required!" -}}
  {{- end -}}

  {{- range $_, $host := $ingressHosts }}
  - {{ $host | quote }}
  {{- end }}
  secretName: {{ . }}
{{- end }}

rules:
{{/*
  devIngressPaths should be considered overrides to the normal paths
*/}}
{{- if $.Values.devIngressPaths }}
  {{- range $_, $devPath := $.Values.devIngressPaths }}
    {{- $devPath := set $devPath "kubeVersion" $kubeVersion }}
    {{- range $_, $host := $ingressHosts }}
  - host: {{ $host | quote }}
    http:
      paths:
      - path: {{ $devPath.path }}
        {{- include "common.ingress.service" $devPath | nindent 8 }}
    {{- end }}
  {{- end }}
{{- end }}

{{- range $_, $path := $ingressPaths }}
  {{- if $ingressHosts }}
  {{- range $_, $host := $ingressHosts }}
  - host: {{ $host | quote }}
    http:
      paths:
        {{- if kindIs "string" $path }}
        - path: {{ $path }}
        {{- include "common.ingress.service" $service | nindent 10 }}
        {{- else }}
        - {{ toYaml $path | indent 10 | trim }}
        {{- end }}
  {{- end }}
  {{- else }}
  - http:
      paths:
        {{- if kindIs "string" $path }}
        - path: {{ $path }}
        {{- include "common.ingress.service" $service | nindent 10 }}
        {{- else }}
        - {{ toYaml $path | indent 10 | trim }}
        {{- end }}
  {{- end }}
{{- end }}

{{- end -}}

{{/*
If AuthN enablement is turned on, renders the additional needed ingress annotations. Else renders nothing.

This macro is intended for use by microservices that wish to have their ingress covered by the AuthN gateway.

A default AuthN HTTP service URL pointing to nucleus-frontend and an HTTP header name for auth token injection
are both generated. NB: The defaults assume that your ingress lives in the same namespace as nucleus-frontend.

You can override both the URL and the header name by adding the value "overrideUrl" and "overrideHeader",
respectively, to the context passed to this macro.
*/}}
{{- define "common.ingress.authNAnnotations" -}}
{{- if $.Values.ingress.authN.enabled }}
{{- $actualHeader := default "X-Authorization" .overrideHeader -}}
{{- $defaultUrl := printf "http://nucleus-frontend.%s.svc.%s/account/auth/service/authenticate?asheader=%s" .Release.Namespace .Values.clusterDomain $actualHeader -}}
{{- $actualUrl := default $defaultUrl .overrideUrl -}}
nginx.ingress.kubernetes.io/auth-response-headers: {{ $actualHeader }}
nginx.ingress.kubernetes.io/auth-url: {{ $actualUrl }}
{{- end }}
{{- end }}

{{/*
For clients using AuthN enablement, an internal URL for the JWKS endpoint.
*/}}
{{- define "common.authN.jwksInternalUrl" -}}
{{- printf "http://nucleus-frontend.%s.svc.%s/account/auth/service/jwks" .Release.Namespace .Values.clusterDomain -}}
{{- end -}}


{{/*
If istio is enabled, renders commonly needed ingress annotations. Else, renders nothing.

The service name is used in at least one of the annotations. You can override the default
service name by adding the value "overrideName" to the context passed to this macro.

If you overrode the default service name when using the `common.ingress.fullspec` template,
then you should override with the same value when using this template.
*/}}
{{- define "common.ingress.istioAnnotations" -}}
{{- if $.Values.istio.enabled }}
{{- $serviceName := default (include "common.fullname" .) .overrideName -}}
nginx.ingress.kubernetes.io/service-upstream: "true"
nginx.ingress.kubernetes.io/upstream-vhost: {{ $serviceName }}.{{ .Release.Namespace }}.svc.{{ .Values.clusterDomain }}
{{- end }}
{{- end }}

{{- define "common.ingress.service" -}}
{{- if semverCompare "<1.19-0" .kubeVersion -}}
backend:
  serviceName: {{ .name }}
  servicePort: {{ .port }}
{{- else -}}
pathType: ImplementationSpecific
backend:
  service:
    name: {{ .name }}
    port:
      {{- if kindIs "string" .port }}
      name: {{ .port }}
      {{- else }}
      number: {{ .port }}
      {{- end }}
{{- end -}}
{{- end -}}
