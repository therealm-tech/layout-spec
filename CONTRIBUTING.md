# Contributing

Changes go through GitHub on
[therealm-tech/layout-spec](https://github.com/therealm-tech/layout-spec): the
pre-commit hooks pass locally, the same hooks and a chart render pass in CI.

## Development setup

See [README.md](README.md#getting-started) for what the repository holds and
how the chart is used.

Tools the hooks and the chart render shell out to:

| Tool | Version | Used by |
| --- | --- | --- |
| [pre-commit](https://pre-commit.com) | ≥ 4 | every hook |
| [Go](https://go.dev/doc/install) | ≥ 1.26 | installing `jsonnetfmt` and `helm-docs` below |
| [Helm](https://helm.sh/docs/intro/install/) | ≥ 3.8 | `helm-lint`, chart render |
| [helm-docs](https://github.com/norwoodj/helm-docs) | 1.14.2 | `helm-docs`, `scripts/release.sh` |
| [go-jsonnet](https://github.com/google/go-jsonnet) `jsonnetfmt` | 0.22.0 | `jsonnetfmt` |
| [Trivy](https://trivy.dev/latest/getting-started/installation/) | ≥ 0.76 | `trivy-chart` |

`yamllint`, `actionlint` and `shellcheck` are installed by pre-commit itself.

Install pre-commit:

```sh
uv tool install pre-commit
```

Install `jsonnetfmt` and `helm-docs`:

```sh
go install github.com/google/go-jsonnet/cmd/jsonnetfmt@v0.22.0
```

```sh
go install github.com/norwoodj/helm-docs/cmd/helm-docs@v1.14.2
```

Helm and Trivy have no distro-neutral package: follow their upstream install
pages linked in the table above.

Then, from a fresh clone, install the hooks:

```sh
pre-commit install
```

The setup works when `pre-commit run --all-files` passes.

## Running the tests

The repository has no test suite. The chart is checked by `helm lint` (a
pre-commit hook) and by rendering it against each cluster of the example,
which CI does too:

```sh
helm template root-mgmt-1 charts/therealm-layout --namespace argocd -f example/clusters/mgmt-1/cluster.yaml --set cluster=mgmt-1
```

Replace `mgmt-1` with any directory under `example/clusters/`. A change to the
chart or to the layout updates the example in the same change, so that it
keeps rendering and keeps illustrating [SPEC.md](SPEC.md).

## Pre-commit hooks

Hooks must pass before a commit is pushed. Run them all, or one while
iterating:

```sh
pre-commit run --all-files
```

```sh
pre-commit run <hook-id> --all-files
```

The hooks are defined in [`.pre-commit-config.yaml`](.pre-commit-config.yaml):

| Hook | Checks | Fix |
| --- | --- | --- |
| `trailing-whitespace`, `end-of-file-fixer` | whitespace | fixes itself; re-run |
| `check-yaml` | YAML parses | fix the file |
| `check-added-large-files`, `check-merge-conflict`, `detect-private-key` | accidental commits | remove the file or marker |
| `yamllint` | YAML style, per [`.yamllint.yaml`](.yamllint.yaml) | fix the file |
| `actionlint` | GitHub Actions workflows | fix the workflow |
| `shellcheck` | shell scripts, such as [`scripts/release.sh`](scripts/release.sh) | fix the script |
| `no-co-authors` | no `Co-Authored-By:` or `Generated with` line in a commit message | rewrite the message |
| `jsonnetfmt` | Jsonnet formatting | fixes itself; re-run |
| `helm-lint` | `charts/therealm-layout`, with `values-lint.yaml` | fix the chart |
| `helm-docs` | the chart's `README.md` matches its `values.yaml` | fixes itself; commit the regenerated README |
| `trivy-chart` | Kubernetes misconfigurations in the rendered chart | fix the chart |

`--no-verify` and `SKIP=` are not the fix: a red hook is a real finding. If a
rule is wrong for this repository, change its configuration in the same change
and say why.

## Continuous integration

| Workflow | Triggers on | What it does | Reproduce locally |
| --- | --- | --- | --- |
| [`quality.yaml`](.github/workflows/quality.yaml) | push to `main`, every pull request | `pre-commit run --all-files`; renders the chart for each cluster of `example/` | the commands above |
| [`chart.yaml`](.github/workflows/chart.yaml) | push of a `chart-*` tag; a manual run on such a tag | checks the tag against the committed versions, packages the chart and pushes it to `oci://ghcr.io/therealm-tech/charts` | `helm package charts/therealm-layout`; the push has no local equivalent |

Both `quality.yaml` jobs are required to merge. `chart.yaml` never runs on a
pull request, and a manual run on anything but a `chart-*` tag fails. Neither
workflow needs a secret: `chart.yaml` pushes with the `GITHUB_TOKEN` GitHub
provides, granted `packages: write` in its publishing job only.
[Dependabot](.github/dependabot.yaml) keeps the pinned actions up to date.

## Submitting a change

- Commit subjects are imperative and lowercase, without a trailing period;
  `git log --oneline` is the reference.
- A change to the layout updates [SPEC.md](SPEC.md), the chart and the
  example together.
- CI is green before the change lands.

## Releasing

The chart is released under `chart-X.Y.Z` tags, `chart-X.Y.Z-rcN` for a
pre-release. [`scripts/release.sh`](scripts/release.sh) is the only supported
way to cut one: `chart.yaml` refuses a tag that disagrees with the committed
versions. Run it from a clean `main`, up to date with `origin`:

```sh
scripts/release.sh --dry-run 0.2.0
```

```sh
scripts/release.sh 0.2.0
```

It sets `version` in [`Chart.yaml`](charts/therealm-layout/Chart.yaml) and
regenerates the chart's README with `helm-docs`. A stable release also moves
the chart's `targetRevision` in
[`example/clusters/mgmt-1/root.yaml`](example/clusters/mgmt-1/root.yaml) and
the `--version` of the registry command in [README.md](README.md); a
pre-release leaves them on the last stable version. It then commits
`release chart <version>`, tags `chart-<version>` and asks before pushing both,
defaulting to no. When `Chart.yaml` already holds the version, it commits
nothing and tags `HEAD`.

Pushing the tag runs `chart.yaml`, which publishes
`oci://ghcr.io/therealm-tech/charts/therealm-layout:<version>`. A chart release
has no GitHub release page. GHCR creates a package private: the
`therealm-layout` package is set to public in its package settings, so that
Helm and Argo CD pull it without credentials.
