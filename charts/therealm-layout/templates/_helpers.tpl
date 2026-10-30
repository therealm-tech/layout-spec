{{/* A repository's layout directory as a path prefix: "" or "some/dir/". */}}
{{- define "therealm-layout.prefix" -}}
{{- with trimAll "/" (default "" .) }}{{ . }}/{{ end -}}
{{- end }}

{{/*
ApplicationSet-syntax declarations prepended to files/template-patch.yaml.
Argo CD renders a templatePatch with the generator parameters only, so the
chart values reach it as literals declared here. The release name is a
`define` because Argo CD v3.5 has no `tpl` to evaluate a template string.
*/}}
{{- define "therealm-layout.patchHeader" -}}
{{ printf "{{- $catalogURL := %s }}" (quote .catalogURL) }}
{{ printf "{{- $catalogRevision := %s }}" (quote .catalogRevision) }}
{{ printf "{{- $catalogPath := %s }}" (quote .catalogPath) }}
{{ printf "{{- $platformURL := %s }}" (quote .platformURL) }}
{{ printf "{{- $platformRevision := %s }}" (quote .platformRevision) }}
{{ printf "{{- $platformPath := %s }}" (quote .platformPath) }}
{{ printf "{{- $helmIgnoreMissingValueFiles := %t }}" .application.helm.ignoreMissingValueFiles }}
{{ printf "{{- $manifestsInclude := %s }}" (quote .application.manifests.include) }}
{{ printf "{{- $manifestsRecurse := %t }}" .application.manifests.recurse }}
{{ printf "{{- $extraSyncOptions := %s | fromJson }}" (toJson (default (list) .application.syncPolicy.syncOptions) | quote) }}
{{ printf "{{- define \"releaseName\" }}%s{{ end }}" .releaseName }}
{{- end }}

{{/*
An ApplicationSet expression rendering `printf .format .args`, shortened to
.max characters: past it, the name keeps its first .max - 9 characters and
gets "-" and 8 characters of its sha256, so two long names stay distinct.
*/}}
{{- define "therealm-layout.shortName" -}}
{{- $max := int .max }}
{{- if lt $max 10 }}{{ fail "names.maxLength must be at least 10" }}{{ end -}}
{{ printf "{{ $name := printf %s }}{{ if gt (len $name) %d }}{{ printf \"%%s-%%s\" (regexReplaceAll \"-+$\" (trunc %d $name) \"\") (sha256sum $name | trunc 8) }}{{ else }}{{ $name }}{{ end }}" .args $max (sub $max 9) }}
{{- end }}
