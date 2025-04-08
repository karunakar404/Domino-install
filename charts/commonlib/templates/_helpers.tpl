{{/* vim: set filetype=mustache: */}}
{{/*
Defines the "root" name used for naming chart resources.
Provides consuming charts the ability to override the default value and still
retain the behavior of other, named-based functions in this library.
*/}}
{{- define "common._rootname" -}}
{{ .Chart.Name }}
{{- end -}}

{{/*
Expand the name of the chart.
*/}}
{{- define "common.name" -}}
{{- default (include "common._rootname" .) .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "common.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default (include "common._rootname" .) .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "common.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create the name of the service account to use.
*/}}
{{- define "common.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "common.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Generate fully-qualified reference to the container image.

Input should be a map with the following values:

registry: Hostname for the docker registry (omit for dockerhub)
repository: Path to the docker image
tag: Docker image tag
*/}}
{{- define "common.imagename" -}}
{{- $imageName := printf "%s:%v" .repository .tag -}}
{{- if .registry -}}
{{- printf "%s/%s" (trimSuffix "/" .registry) $imageName -}}
{{- else -}}
{{- print $imageName -}}
{{- end -}}
{{- end -}}

{{/*
Takes a dict or map and generates labels. Values will be quoted, keys will not.
*/}}
{{- define "common.labelize" -}}
{{- range $k, $v := . }}
{{ $k }}: {{ $v | quote }}
{{- end -}}
{{- end -}}

{{/*
Creates an "apps" API version that is compatible with all Kubernetes versions.
*/}}
{{- define "common.resources.app" -}}
{{- if semverCompare "^1.9-0" .Capabilities.KubeVersion.GitVersion -}}
apps/v1
{{- else if semverCompare "^1.7-0" .Capabilities.KubeVersion.GitVersion -}}
apps/v1beta1
{{- else -}}
extensions/v1beta1
{{- end -}}
{{- end -}}

{{/*
Creates an "ingress" API version that is compatible with all Kubernetes versions.
*/}}
{{- define "common.resources.ingress" -}}
{{- if semverCompare "<1.14-0" .Capabilities.KubeVersion.GitVersion -}}
extensions/v1beta1
{{- else if semverCompare "<1.19-0" .Capabilities.KubeVersion.GitVersion -}}
networking.k8s.io/v1beta1
{{- else -}}
networking.k8s.io/v1
{{- end -}}
{{- end -}}

{{/*
Creates a "PodDisruptionBudget" API version that is compatible with all Kubernetes versions.
*/}}
{{- define "common.resources.poddisruptionbudget" -}}
{{- if semverCompare "<1.21-0" .Capabilities.KubeVersion.GitVersion -}}
policy/v1beta1
{{- else -}}
policy/v1
{{- end -}}
{{- end -}}

{{/*
Creates a "CronJob" API version that is compatible with all Kubernetes versions.
*/}}
{{- define "common.resources.cronjob" -}}
{{- if semverCompare "<1.21-0" .Capabilities.KubeVersion.GitVersion -}}
batch/v1beta1
{{- else -}}
batch/v1
{{- end -}}
{{- end -}}

{{/*
abstract: |
  Joins a list of prefixed values into a space seperated string
  Variation on the joins from here:
  https://github.com/openstack/openstack-helm-infra/tree/master/helm-toolkit/templates/utils
values: |
  test:
    - foo
    - bar
usage: |
  {{ tuple "(separator)" .Values.test | include "common.joinList" }}
return: |
  foo(separator)bar
*/}}
{{- define "common.joinList" -}}
{{- $sep := index . 0 -}}
{{- $local := dict "first" true -}}
{{- range $k, $v := index . 1 -}}{{- if not $local.first -}}{{- $sep -}}{{- end -}}{{- $v -}}{{- $_ := set $local "first" false -}}{{- end -}}
{{- end -}}

{{/*
Create the name of globally (un-namespaced) resources such as PSPs or ClusterRole.
*/}}
{{- define "common.globalname" -}}
  {{- printf "domino-%s-%s" .Release.Namespace (include "common.fullname" .) -}}
{{- end -}}

{{/*
Istio job exit code
*/}}
{{- define "common.istioJobExit" -}}
{{- $istio := ((.Values.global).istio) | default .Values.istio | default dict -}}
{{- if $istio.enabled | default false -}}
trap "curl -X POST http://localhost:15020/quitquitquit" INT TERM EXIT
{{- end -}}
{{- end -}}
