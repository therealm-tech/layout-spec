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
| [Helm](https://helm.sh/docs/intro/install/) | ≥ 3 | `helm-lint`, chart render |
| [helm-docs](https://github.com/norwoodj/helm-docs) | 1.14.2 | `helm-docs` |
| [go-jsonnet](https://github.com/google/go-jsonnet) `jsonnetfmt` | 0.22.0 | `jsonnetfmt` |
| [Trivy](https://trivy.dev/latest/getting-started/installation/) | ≥ 0.76 | `trivy-chart` |

`yamllint` and `actionlint` are installed by pre-commit itself.

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

Both jobs are required to merge. The workflow needs no secret.
[Dependabot](.github/dependabot.yaml) keeps the pinned actions up to date.

## Submitting a change

- Commit subjects are imperative and lowercase, without a trailing period;
  `git log --oneline` is the reference.
- A change to the layout updates [SPEC.md](SPEC.md), the chart and the
  example together.
- CI is green before the change lands.
