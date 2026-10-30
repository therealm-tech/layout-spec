# The therealm Argo CD Repository Layout

| | |
|---|---|
| Category | Internal specification |
| Scope | Repository layout for Argo CD deployments |

## Abstract

This document specifies where the files that describe Argo CD deployments
live, what each file means, and how files at different levels combine into
the description of one deployed instance. It defines two roles, the repo
catalogue and the repo platform, which one repository may hold together.
Everything that operates on the layout (installing Argo CD, synchronising
applications, validating files) is outside its scope.

## Status of This Memo

This document is the internal specification of this project. It is
normative for any repository that claims to follow the therealm layout. It
is not an IETF document and makes no claim to be one. Distribution of this
memo is unlimited.

## Table of Contents

1. [Introduction](#1-introduction)
2. [Requirements Language](#2-requirements-language)
3. [Terminology](#3-terminology)
4. [Repositories and Revisions](#4-repositories-and-revisions)
5. [Names](#5-names)
6. [The Repo Catalogue](#6-the-repo-catalogue)
7. [The Repo Platform](#7-the-repo-platform)
8. [The `app.yaml` File](#8-the-appyaml-file)
9. [The `cluster.yaml` File](#9-the-clusteryaml-file)
10. [Resolution of an Instance](#10-resolution-of-an-instance)
11. [Security Considerations](#11-security-considerations)
12. [IANA Considerations](#12-iana-considerations)
13. [References](#13-references)
- [Appendix A. Worked Example](#appendix-a-worked-example)

## 1. Introduction

The layout separates three concerns:

- **what** can be deployed: the catalogue of applications, with their
  sources and default configuration;
- **how** an application is configured in a given environment;
- **where** it is actually deployed: on which cluster, in which environment,
  under which instance name.

Each concern has its own directory tree; `clusters/` also carries the
configuration specific to a cluster (Sections 7.2, 9). An application is
deployed only where an instance declares it. No level other than the
instance deploys anything by itself.

A file or directory that this document does not specify has no meaning in
the layout and is not read, except as part of the content of a source
(Sections 3, 8.2).

## 2. Requirements Language

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT",
"SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and
"OPTIONAL" in this document are to be interpreted as described in BCP 14
[RFC2119] [RFC8174] when, and only when, they appear in all capitals, as
shown here.

## 3. Terminology

- **Repo catalogue**: The role of providing `apps/`, held by a repository at
  a layout root. Each cluster names the repository and layout root that hold
  it (Section 9).

- **Repo platform**: The role of providing `envs/` and `clusters/`, held by
  a repository at a layout root. Each cluster names the repository and
  layout root that hold it (Section 9).

- **Layout root**: The directory of a repository under which a role's part
  of the layout starts. Paths under `apps/` are relative to the repo
  catalogue's layout root; paths under `envs/` and `clusters/` are relative
  to the repo platform's. `path` set together with `url` is relative to the
  root of that repository (Section 8.2); `repo.catalog.path` and
  `repo.platform.path` are relative to the root of their repository
  (Section 9).

- **Catalogue**: The set of apps of a repo catalogue (Section 6.1).

- **App**: An entry of the catalogue, identified by its name `<app>`.

- **Env (environment)**: A name grouping instances, which can carry
  overrides under `envs/<env>/`.

- **Cluster**: A Kubernetes cluster known to Argo CD, identified by its name
  `<cluster>`, which is the name Argo CD knows it by.

- **Cluster×app**: The level `clusters/<cluster>/<app>/` (Section 7.2).

- **Instance**: One deployment of one app in one env on one cluster,
  identified by the tuple (`<cluster>`, `<env>`, `<app>`, `<instance>`).
  Each instance corresponds to one Argo CD Application.

- **Level**: One of the four places an instance's configuration is read
  from, from least to most specific: catalogue, env, cluster×app, instance.
  The catalogue level is named after the catalogue: it is
  `apps/<app>/app.yaml` and `apps/<app>/values.yaml` in the repo catalogue.

- **Set**: A field of `app.yaml` or `cluster.yaml` is set when its key is
  present with a non-null value. A key with a null value is equivalent to an
  absent key.

- **Plain manifests**: Kubernetes manifests deployed as they are written,
  with no Helm, Kustomize or Jsonnet processing.

- **Source**: What an app deploys: a Helm chart, or a Kustomize, Jsonnet or
  plain-manifests directory, designated by `chart` or `path` (Section 8.2),
  together with the files those tools read from it.

- **Effective configuration**: The `app` mapping that results from combining
  the `app.yaml` files of an instance's levels (Section 10.2).

- **Effective revision**: The revision the app's source is read at:
  `revision` of the effective configuration when `url` is set,
  `repo.catalog.revision` when it is not (Section 8.2).

## 4. Repositories and Revisions

For a given cluster, the layout has two roles, the repo catalogue and the
repo platform, each held by a repository. One repository MAY hold both
roles. When distinct repositories hold them, the repo catalogue can be
public while the repo platform is confidential.

Each role has a layout root. The layout root MAY be the root of the
repository that holds the role; it MAY also be a subdirectory, which lets a
repository hold the layout next to unrelated content. When one repository
holds both roles, both layout roots MAY be the same directory.

The repo catalogue provides, under its layout root:

```text
apps/
```

The repo platform provides, under its layout root:

```text
envs/
clusters/
```

Each cluster states in its `cluster.yaml` (Section 9) which repo catalogue
and which repo platform it reads, and at which revisions. For an instance on
that cluster:

- `apps/<app>/app.yaml` and `apps/<app>/values.yaml` are read from the repo
  catalogue at `repo.catalog.revision`;
- the app's source is read at its effective revision (Section 8.2). A
  source held by the repo catalogue is therefore always read at
  `repo.catalog.revision`, the same revision as the catalogue level files.
  Everything that belongs to the source, such as a chart's own `values.yaml`, or
  `apps/<app>/manifests/` and `apps/<app>/lib/` when they are part of the
  source (Sections 6.5, 6.6), is read with it;
- every file under `envs/` and `clusters/`, except
  `clusters/<cluster>/cluster.yaml` and `clusters/<cluster>/root.yaml`, is
  read from the repo platform at `repo.platform.revision`.

## 5. Names

`<app>`, `<env>`, `<cluster>` and `<instance>` are directory names. Each
MUST be a valid DNS label as defined in Section 2.1 of [RFC1123], restricted
to lowercase: lowercase letters, digits and `-`, starting and ending with a
letter or a digit, at most 63 characters.

Under `clusters/<cluster>/`, an `<env>` name MUST NOT be the name of an app
of the repo catalogue that `<cluster>` reads: `clusters/<cluster>/<name>/`
is a cluster×app directory when `<name>` is such an app (Section 7.2), and
an env directory otherwise (Section 7.3). This classification is made
against the repo catalogue at the `repo.catalog.revision` read by that
cluster: adding an app to the catalogue, or moving that revision, can turn
an existing env directory into a cluster×app directory.

The file names `cluster.yaml` and `root.yaml` are reserved directly under
`clusters/<cluster>/`. The layout assigns a meaning to `cluster.yaml`
(Section 9). It reserves the OPTIONAL file `root.yaml` for bootstrapping
Argo CD; its content is outside the scope of this document.

## 6. The Repo Catalogue

```text
apps/
  <app>/
    app.yaml          defines the app (Section 6.1)
    values.yaml       OPTIONAL
    charts/
      <chart>/        OPTIONAL  Helm chart
    lib/              OPTIONAL  Jsonnet libraries
    manifests/        OPTIONAL  plain manifests, Kustomize or Jsonnet
```

### 6.1. Membership

An app is part of the catalogue if and only if `apps/<app>/app.yaml` exists
at `repo.catalog.revision` (Section 4). A directory under `apps/` without
`app.yaml` is not an app, and nothing it contains is read.

### 6.2. `apps/<app>/app.yaml`

The catalogue level of the app's configuration (Section 8). It MUST set
exactly one of `chart` and `path`. Every field, `chart`, `path` and `url`
included, MAY be set at any level; the constraints of Section 8.2 apply to
the effective configuration.

### 6.3. `apps/<app>/values.yaml`

The catalogue level of the app's Helm values. It applies only when the
app's source is a Helm chart (Section 8.3).

### 6.4. `apps/<app>/charts/<chart>/`

A Helm chart held by the repo catalogue. An app uses it by setting `path` to
`apps/<app>/charts/<chart>` with no `url`. An app MAY hold several charts;
only the one designated by `path` is deployed.

### 6.5. `apps/<app>/manifests/`

The source of a non-Helm app held by the repo catalogue, designated by
setting `path` to `apps/<app>/manifests` with no `url`. `manifests/` has a
meaning only as the target of `path`; when the app's source is elsewhere,
`apps/<app>/manifests/` is not read. Its type is decided by the rules of
Section 8.3.

### 6.6. `apps/<app>/lib/`

Jsonnet libraries of the app. A Jsonnet file of `manifests/` imports them
by a path relative to itself (`../lib/<file>.libsonnet`); the layout defines
no library search path. They are read together with the source, at its
revision. `lib/` has a meaning only when the source is the Jsonnet
directory `apps/<app>/manifests` (no `url`); otherwise the layout gives it
no meaning.

## 7. The Repo Platform

```text
envs/
  <env>/
    <app>/
      app.yaml                 OPTIONAL
      values.yaml              OPTIONAL
clusters/
  <cluster>/
    cluster.yaml               REQUIRED (Section 7.4)
    root.yaml                  OPTIONAL, reserved (Section 5)
    <app>/                     cluster×app level
      app.yaml                 OPTIONAL
      values.yaml              OPTIONAL
    <env>/
      <app>/
        <instance>/
          app.yaml             defines the instance, MAY be empty (Section 7.3)
          values.yaml          OPTIONAL
          manifests/           OPTIONAL  plain manifests
```

### 7.1. Environments

`envs/<env>/<app>/app.yaml` and `envs/<env>/<app>/values.yaml` are the env
level of the app's configuration and Helm values. Both are OPTIONAL. An env
with no override needs no directory under `envs/`. A file under
`envs/<env>/<app>/` has no effect unless an instance of `<app>` in `<env>`
exists.

### 7.2. Cluster×app

`clusters/<cluster>/<app>/app.yaml` and `clusters/<cluster>/<app>/values.yaml`
are the cluster×app level: they apply to every instance of `<app>` on
`<cluster>`, whatever its env. Both are OPTIONAL.

### 7.3. Instances

An instance exists if and only if
`clusters/<cluster>/<env>/<app>/<instance>/app.yaml` exists. Its content is
the instance level of the configuration and MAY be empty: an empty file
deploys the instance with the configuration resolved from the other levels.

`<app>` MUST be an app of the repo catalogue read by `<cluster>`, at
`repo.catalog.revision` (Section 5). `<env>` is
any name allowed by Section 5; no file under `envs/<env>/` is required.

`values.yaml` in the instance directory is the instance level of the Helm
values.

`manifests/` in the instance directory holds plain manifests deployed by the
same instance, alongside the app's source: the `.yaml` files at any depth
under it. Files with other extensions are not read. Unlike the
plain-manifests rule of Section 8.3, which takes only the files directly in
the directory, this rule includes subdirectories. `manifests/` MUST NOT
contain, at any depth, a kustomization file (Section 8.3), and a manifest
under it MUST NOT declare a resource that the app's source also renders.

### 7.4. Clusters

`clusters/<cluster>/cluster.yaml` is REQUIRED for every
`clusters/<cluster>/` directory (Section 9).

## 8. The `app.yaml` File

### 8.1. Structure

An `app.yaml` file is a YAML [YAML] document whose only root key is `app`.
It MUST NOT contain any other root key. An empty file, or a file whose `app`
key holds an empty mapping or null, contributes nothing to the effective
configuration.

| Field | Type | Meaning |
|---|---|---|
| `url` | string | Repository of the app's source (Section 8.2). |
| `chart` | string | Name of a Helm chart in the repository `url`. |
| `path` | string | Directory of the app's source (Section 8.2). |
| `revision` | string | Chart version when `chart` is set; Git revision of `url` when `path` and `url` are set. MUST NOT be set when `url` is not set (Section 8.2). |
| `project` | string | Argo CD project of the instance. |
| `namespace` | string | Namespace the instance deploys into. |
| `syncOptions` | sequence of strings | Argo CD sync options of the instance [ARGOCD]. |
| `managedNamespaceMetadata` | mapping | Labels and annotations Argo CD sets on `namespace` [ARGOCD]. |

Except as Section 6.2 requires for the catalogue level, every field is
OPTIONAL at a given level. The constraints below apply to the effective
configuration (Section 10). `url`, `chart`, `path`, `revision`, `namespace`
and `project`, when set in the effective configuration, MUST be
non-empty. Keys of `app` other than those in the table have no meaning in
the layout and are not read.

### 8.2. Source

Exactly one of `chart` and `path` MUST be set.

A repository URL, in `url` and in `cluster.yaml` (Section 9), is written as
follows: an OCI registry without a scheme (`<host>/<path>`); an HTTP(S) Helm
chart repository with its scheme (`https://...`); a Git repository in any
Git URL form that Argo CD accepts [ARGOCD].

When `chart` is set, `url` and `revision` MUST be set, `url` MUST be a Helm
chart repository or an OCI registry, and `revision` is the chart version.

When `path` is set and `url` is not, the source lives in the repo catalogue
and `path` is relative to its layout root. `path` MUST then be either
`apps/<app>/charts/<chart>` or `apps/<app>/manifests`, where `<app>` is the
instance's own app. `revision` MUST NOT be set when `url` is not set; the
source is then read at `repo.catalog.revision` (Section 9), and the
catalogue is pinned only through that field. A source held by the repo
catalogue MUST NOT read files of the repo catalogue outside `apps/<app>/`.

When `path` and `url` are set, `url` MUST be a Git repository, `path` is
relative to its root, and `revision` MUST be set.

When `url` is set, `revision` selects the revision of the app's source
only. Every level file listed in Section 10.1 is read at the revision
Section 4 assigns to it, whatever `revision` is.

### 8.3. Source type

The source is a Helm chart if and only if `chart` is set, or `url` is not
set and `path` is `apps/<app>/charts/<chart>`. A directory designated by
`path` MUST NOT contain a `Chart.yaml` unless `url` is not set and `path` is
`apps/<app>/charts/<chart>`.

Any other source is Kustomize, Jsonnet or plain manifests, decided by the
content of the directory designated by `path`, as it is at the source's
revision, whether that directory is `apps/<app>/manifests/` or a directory
of another repository:

1. **Kustomize** [KUSTOMIZE] if it contains a kustomization file directly
   in it (`kustomization.yaml`, `kustomization.yml` or `Kustomization`), which
   MAY reference remote bases;
2. otherwise **Jsonnet** [JSONNET] if it contains `*.jsonnet` files directly
   in it. Each of them is evaluated to one manifest or an array of
   manifests, and the `.yaml` files directly in the directory are deployed
   alongside as plain manifests. Other files, directly in the directory or
   below it, are read only through Jsonnet imports;
3. otherwise **plain manifests**: the `.yaml` files directly in that
   directory. Files in its subdirectories, and files with other extensions,
   are not read.

A plain-manifests `.yaml` file, here or in an instance's `manifests/`
(Section 7.3), MAY contain several YAML documents.

`values.yaml` files of the levels apply to Helm sources only. For any other
source type, they are not read.

### 8.4. Namespace, Project and Names

When `namespace` is set, it is the Helm release namespace and the
namespace of every namespaced resource that does not carry its own; a
resource that carries a namespace keeps it. When it is not set, the instance
has no default namespace: every namespaced resource it deploys MUST carry
its own namespace.

`project` is OPTIONAL in the effective configuration. When it is not set,
the layout assigns no project, and the system deploying the layout decides
which project the instance belongs to.

The layout assigns no Helm release name; the system deploying the layout
chooses it. The layout assigns no name to the Argo CD Application of an
instance; the system deploying the layout chooses it.

The name of an instance's Argo CD Application and the Helm release name, as
chosen by the deploying system, MUST be at most 53 characters: 53 is Helm's
release name limit, and keeps the name valid as an Argo CD tracking label
value, which is limited to 63 characters.

When such a name is built from `<cluster>`, `<env>`, `<app>` and
`<instance>` and exceeds 53 characters, it SHOULD be shortened as follows:
take its first 44 characters, remove any trailing `-`, append `-`, then
append the first 8 characters of the lowercase hexadecimal SHA-256 [RFC6234]
digest of the full name, encoded in UTF-8. The result is at most 53
characters, and names that share their first 44 characters differ by their
digest. For example, `prod-eu-west-1-production-kube-prometheus-stack-default`
(55 characters) becomes `prod-eu-west-1-production-kube-prometheus-st-c3a6b83a`
(53 characters).

`syncOptions` and `managedNamespaceMetadata` are passed to Argo CD as they
are. Creating `namespace` is requested through `syncOptions`
(`CreateNamespace=true`); the layout has no separate field for it.
`managedNamespaceMetadata` has no effect unless `namespace` is set and
`syncOptions` contains `CreateNamespace=true` [ARGOCD].

## 9. The `cluster.yaml` File

`clusters/<cluster>/cluster.yaml` is a YAML document whose only root key is
`repo`. It MUST NOT contain any other root key. It states which
repositories hold the repo catalogue and the repo platform of the cluster,
and at which revisions they are read:

| Field | Type | Meaning |
|---|---|---|
| `repo.catalog.url` | string | URL of the Git repository holding the repo catalogue, in the Git form of Section 8.2. REQUIRED. |
| `repo.catalog.revision` | string | Revision at which `apps/<app>/app.yaml`, `apps/<app>/values.yaml` and every source held by the repo catalogue are read. REQUIRED. |
| `repo.catalog.path` | string | Layout root of the repo catalogue. OPTIONAL; not set or empty means the repository root. |
| `repo.platform.url` | string | URL of the Git repository holding the repo platform, in the Git form of Section 8.2. REQUIRED. |
| `repo.platform.revision` | string | Revision at which the files of the repo platform are read. REQUIRED. |
| `repo.platform.path` | string | Layout root of the repo platform. OPTIONAL; not set or empty means the repository root. |

Keys under `repo` other than those in the table have no meaning in the
layout and are not read. `repo.platform` MUST designate the repository and
layout root that hold this `cluster.yaml`. The revision at which
`cluster.yaml` itself is read is outside the scope of this document.

## 10. Resolution of an Instance

### 10.1. Levels

The configuration of the instance (`<cluster>`, `<env>`, `<app>`,
`<instance>`) is read from four levels, from least to most specific:

| Level | `app.yaml` | `values.yaml` | Repository |
|---|---|---|---|
| catalogue | `apps/<app>/app.yaml` | `apps/<app>/values.yaml` | repo catalogue |
| env | `envs/<env>/<app>/app.yaml` | `envs/<env>/<app>/values.yaml` | repo platform |
| cluster×app | `clusters/<cluster>/<app>/app.yaml` | `clusters/<cluster>/<app>/values.yaml` | repo platform |
| instance | `clusters/<cluster>/<env>/<app>/<instance>/app.yaml` | `clusters/<cluster>/<env>/<app>/<instance>/values.yaml` | repo platform |

A missing file contributes nothing. The catalogue and instance `app.yaml`
files define the app and the instance (Sections 6.1, 7.3); every other level
file is optional.

### 10.2. Effective `app.yaml`

The effective configuration is the catalogue `app` mapping, overridden in
turn by the env, cluster×app and instance `app` mappings:

- when a key holds a mapping at both levels, the two mappings are combined
  key by key, recursively;
- otherwise, a key set at the more specific level replaces the value at the
  less specific one. Scalars and sequences are replaced as a whole: a
  sequence is never concatenated with the sequence of another level.
  `false` or an empty sequence is set, and replaces the value below it; a
  null value is not set, and does not.

A more specific level can therefore replace any value, but never remove a
key that a less specific level sets. An app whose catalogue `app.yaml` sets
`chart` cannot become a `path` app at a lower level, and a `namespace` set
by the catalogue cannot be removed.

In particular, labels and annotations under `managedNamespaceMetadata`
accumulate across levels, while `syncOptions` set at a level replaces the
whole list of the levels below it.

### 10.3. Effective Helm values

For a Helm source, the values files of the four levels are passed to Helm in
order, catalogue first and instance last, and combined with Helm's own
semantics [HELM], including for null values. The chart's own `values.yaml`
is the base they all override.

### 10.4. Deployed content

An instance deploys, to the cluster `<cluster>`, into the namespace of its
effective configuration when one is set, and under its Argo CD project when
one is set (Section 8.4):

- the app's source, rendered according to its type (Section 8.3), with the
  effective Helm values when it is a Helm chart;
- the plain manifests of the instance's `manifests/` directory, if any
  (Section 7.3).

The system deploying the layout chooses the Argo CD project when the
effective configuration sets none, the name of the instance's Argo CD
Application, and the Helm release name of a Helm source (Section 8.4).

## 11. Security Considerations

The repo catalogue provides only what is common to every deployment of an
app, and it may be public. Files under `apps/` MUST NOT contain secrets, and
SHOULD NOT contain facts specific to an env or a cluster, such as hostnames,
network ranges or capacity. Those belong to the repo platform, whose
confidentiality is what the split exists for.

The split protects confidentiality, not integrity. Through `app.yaml`
(`url`, `chart`, `path`, `revision`, `project`, `namespace`, `syncOptions`,
`managedNamespaceMetadata`), `values.yaml`, the sources it holds under
`apps/<app>/`, and the remote bases of its Kustomize sources, the repo
catalogue decides what is deployed, into which namespace, under which Argo
CD project, and with which namespace labels, on every cluster that has an
instance of the app. Write access to the repo catalogue at a revision a
cluster reads (`repo.catalog.revision`) is equivalent to write access to
every cluster that has an instance of the app. A source, remote base or
chart dependency outside both repositories extends the same trust to that
repository.

The repo platform chooses which repo catalogue a cluster reads, and at
which revision, through `repo.catalog` in `cluster.yaml`. Its `app.yaml`
levels can replace any catalogue value, `chart`, `path`, `url` and
`revision` included, but cannot remove any key the catalogue `app.yaml` sets
(Section 10.2); its `values.yaml` levels can remove catalogue values with
null (Section 10.3).

Adding an app named like an env reclassifies that env's directory on every
cluster that reads the catalogue (Section 5), which removes its
instances.

## 12. IANA Considerations

This document has no IANA actions.

## 13. References

### 13.1. Normative References

- **[ARGOCD]** Argo CD, "Argo CD Documentation",
  <https://argo-cd.readthedocs.io/en/stable/>.
- **[HELM]** Helm, "Values Files",
  <https://helm.sh/docs/chart_template_guide/values_files/>.
- **[JSONNET]** Jsonnet, "Jsonnet Language Reference",
  <https://jsonnet.org/ref/language.html>.
- **[KUSTOMIZE]** Kubernetes, "Kustomize",
  <https://kubectl.docs.kubernetes.io/references/kustomize/>.
- **[RFC1123]** Braden, R., Ed., "Requirements for Internet Hosts -
  Application and Support", STD 3, RFC 1123,
  <https://www.rfc-editor.org/info/rfc1123>.
- **[RFC2119]** Bradner, S., "Key words for use in RFCs to Indicate
  Requirement Levels", BCP 14, RFC 2119,
  <https://www.rfc-editor.org/info/rfc2119>.
- **[RFC6234]** Eastlake 3rd, D. and T. Hansen, "US Secure Hash Algorithms
  (SHA and SHA-based HMAC and HKDF)", RFC 6234,
  <https://www.rfc-editor.org/info/rfc6234>.
- **[RFC8174]** Leiba, B., "Ambiguity of Uppercase vs Lowercase in RFC 2119
  Key Words", BCP 14, RFC 8174,
  <https://www.rfc-editor.org/info/rfc8174>.
- **[YAML]** "YAML Ain't Markup Language (YAML) Version 1.2",
  <https://yaml.org/spec/1.2.2/>.

### 13.2. Informative References

This document has no informative references.

## Appendix A. Worked Example

This appendix is informative.

[`example/`](example/) is a repository following this layout, with the repo
catalogue and the repo platform held by the same repository. Its catalogue
holds four apps:

- a Helm chart from an OCI registry (`argocd`);
- a Helm chart held by the repo catalogue (`whoami`);
- a Kustomize source (`katib`);
- a Jsonnet source with a library (`team-quotas`).

It has three envs and three clusters, one of which holds two envs and one
of which pins the repo catalogue to a tag.

[`charts/therealm-layout/`](charts/therealm-layout/) is a Helm chart that
implements this layout for Argo CD; it is outside the scope of this
document.
