{{/* vim: set filetype=mustache: */}}

{{/*
Returns the domain for the intra-cluster DNS. This defaults to "cluster.local"
*/}}
{{- define "common.clusterDomain" -}}
{{- .Values.clusterDomain | default "cluster.local" -}}
{{- end -}}

{{/*
Return full IdP private oidc server url
*/}}
{{- define "common.auth.idp.privateOidcServerUrl" -}}
{{- $defaultUrl := printf "http://keycloak-http.%s.svc.%s" .Release.Namespace (include "common.clusterDomain" . ) -}}
{{- ((.Values.config).idp).privateOidcServerUrl | default $defaultUrl -}}
{{- end -}}

{{/*
Return full IdP public oidc server url
*/}}
{{- define "common.auth.idp.publicOidcServerUrl" -}}
{{- $value := ((.Values.config).idp).publicOidcServerUrl | default .Values.publicDomain -}}
  {{- if empty $value -}}
  {{- fail "Either the .publicDomain or .config.idp.publicOidcServerUrl must be set in the values" -}}
  {{- end -}}
{{ $value }}
{{- end -}}

{{/*
Domino realm name
*/}}
{{- define "common.auth.idp.dominoRealm" -}}
{{- ((.Values.config).idp).dominoRealm | default "DominoRealm" -}}
{{- end -}}

{{- define "common.auth.idp.privateDominoRealmBaseUrl" -}}
{{ include "common.auth.idp.privateOidcServerUrl" . }}/auth/realms/{{ include "common.auth.idp.dominoRealm" . }}
{{- end -}}

{{/*
Enforces authentication on HTTP requests.
This is done via Istio by creating a RequestAuthentication resource that validates the token
with the identity provider (e.g. keycloak) keys using its JWKS endpoint, and an AuthorizationPolicy
that only allows access to requests that were successfully authenticated.
*/}}
{{- define "common.auth.http" -}}
apiVersion: security.istio.io/v1
kind: RequestAuthentication
metadata:
  name: "{{ include "common.fullname" . }}"
spec:
  selector:
    matchLabels:
      {{- include "common.labels.selector" . | nindent 6 }}
  jwtRules:
  - issuer: "{{ include "common.auth.idp.publicOidcServerUrl" . }}/realms/{{ include "common.auth.idp.dominoRealm" . }}"
    jwksUri: "{{ include "common.auth.idp.privateDominoRealmBaseUrl" . }}/protocol/openid-connect/certs"
    forwardOriginalToken: true
    outputClaimToHeaders:
    - header: "ddl-auth-principal-id"
      claim: "sub"
    - header: "ddl-auth-idp-id"
      claim: "idp_id"
    - header: "ddl-auth-audience"
      claim: "aud"
---
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: "{{ include "common.fullname" . }}"
spec:
  selector:
    matchLabels:
      {{- include "common.labels.selector" . | nindent 6 }}
  action: ALLOW
  rules:
  - from:
    - source:
        requestPrincipals: ["*"]
  {{ range $_, $endpoint := ((.Values.auth).http).anonymousEndpoints }}
  {{- $methods := $endpoint.methods -}}
  {{- $paths := $endpoint.paths -}}
  - to:
    - operation:
        methods: {{ toJson $methods }}
        paths: {{ toJson $paths }}
  {{ end }}
{{- end -}}
