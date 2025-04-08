# Commonlib: Domino Helm "Common" Macro Template Library

Commonlib is a library of macro templates that are used throughout Domino charts, unifying common functions across Domino charts, providing (some) degree of consistency across charts, and ensuring things are done in a fashion compatible with a Domino deployment (ie composition of image names, etc.).

## Basic usage

Examining other charts is probably the best way to get a feel for how we're using these, but here is an example of a common function:

    {{/*
    Prints the labels frequently used in selector clauses.
    */}}
    {{- define "common.labels.selector" -}}
    app.kubernetes.io/name: {{ include "common.name" . }}
    app.kubernetes.io/instance: {{ .Release.Name }}
    {{- end -}}

And how it might be used in a chart:

    spec:
      selector:
        matchLabels:
          {{- include "common.labels.selector" $ | nindent 6 }}

### Usage in upstream charts

We modify upstream charts, replacing their functions with ours where there's overlap, to ensure things are done as we need.

However, to avoid the surface area of our customizations, you can actually insert the commonlib macro into the chart's own `templates/_helper.tpl` macro:

    {{/*
    Selector labels
    */}}
    {{- define "grafana.selectorLabels" -}}
    {{- include "common.labels.selector" . -}}
    {{- end -}}

Then unmodified instances of the original chart's macro pick up the change.

## Workflow when updating commonlib

Charts that use commonlib have their dependency on it setup to pull from `gcr.io`:

    dependencies:
    - name: commonlib
      version: 0.13.0
      repository: oci://gcr.io/domino-eng-service-artifacts

### Merging changes

Because CircleCI builds and pushes chart changes to `gcr.io`, you will need to make a PR for commonlib, and then a separate PR for your chart using commonlib.

When you push a commit, any given chart will be pushed to `gcr.io` with the version tag composed of `<version-number>-<branch name>`. So if it's commonlib version `0.13.0` and your branch is named `update-commonlib`, the chart version in gcr.io will be named `0.13.0-update-commonlib`.

So a workflow you can use while developing is:

* Push your commonlib changes to github and make a PR
* Watch circle build and publish your branch's version of commonlib
* Verify the version name pushed to `gcr.io` in the `publish_charts_gcr` job and note it
  * Let's say it's `0.13.0-update-commonlib`
* In a _separate branch_ for your chart changes, update its `Chart.yaml` commonlib dependency version to `0.13.0-update-commonlib`
* When you're ready to merge everything, merge the commonlib PR first
* Wait for the chart to build and publish in the master branch
* Update your individual chart's `Chart.yaml` commonlib dependency version to `0.13.0`
* Merge this final version of your individual chart

### Updating chart dependencies

Chart dependencies are not stored in the repo, and must be built to test a chart locally.

First, to work with `gcr.io` you must have the `HELM_EXPERIMENTAL_OCI` variable set to `1`:

    export HELM_EXPERIMENTAL_OCI=1

Second, you must authenticate to `gcr.io`:

    export GCR_PASSWORD=<base64-encoded gcr password string>
    helm registry login -u _json_key -p "$(echo -n $GCR_PASSWORD | base64 -d)" gcr.io

You can get the GCR\_PASSWORD string from `resources/deployer/defaults/mirrors.yaml` in the `platform-apps` repo under `registry.helm.v3.password`.

Once you've authenticated, this will be stored and you should not need to run it again.

To actually update the chart dependency, run `helm dep update`:

    # helm dep update
    Getting updates for unmanaged Helm repositories...
    ...Unable to get an update from the "oci://gcr.io/domino-eng-service-artifacts" chart repository:
            tag explicitly required
    Saving 1 charts
    Downloading commonlib from repo oci://gcr.io/domino-eng-service-artifacts
    0.13.0: Pulling from gcr.io/domino-eng-service-artifacts/commonlib
    Deleting outdated charts

### Developing completely locally

While you absolutely must merge your commonlib changes both separately and before your chart changes consuming it, for convenience you can set the `repository` value in `Chart.yaml` to `file://../commonlib` (or some other path, perhaps to a separate checkout of the charts repo) so it will reference the local filesystem rather than the published change. This makes it quicker to make changes to commonlib files directly, as well as avoid having a gcr.io login setup locally.
