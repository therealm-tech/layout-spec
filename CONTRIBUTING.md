# Contributing

Changes go through GitHub on
[therealm-tech/layout-spec](https://github.com/therealm-tech/layout-spec): the
pre-commit hooks pass locally, the same hooks and the chart renders pass in CI.

## Development setup

See [README.md](README.md#getting-started) for what the repository holds and
how the chart is used.

[mise](https://mise.jdx.dev) installs every tool the hooks, the tests and the
tasks run, at the versions pinned in [`mise.toml`](mise.toml) and locked in
[`mise.lock`](mise.lock). Install mise itself, on macOS or Linux:

```bash
curl https://mise.run | sh
```

Other install methods are on [mise's install page](https://mise.jdx.dev/installing-mise.html),
along with how to activate mise in your shell, which puts the tools on your
`PATH`. Then, from a fresh clone, trust the repository's mise configuration, install
the tools and the git hooks:

```bash
mise trust
```

```bash
mise install
```

```bash
task setup
```

The commands contributors run are tasks in [`Taskfile.yml`](Taskfile.yml);
`task --list` shows them. The setup works when `task lint` passes.

## Running the tests

The tests render the chart against each cluster of the example; `helm lint`
runs with the pre-commit hooks. Render every cluster:

```bash
task test
```

Render a single cluster, named after its directory under `example/clusters/`:

```bash
task render CLUSTER=mgmt-1
```

A change to the chart or to the layout updates the example in the same
change, so that it keeps rendering and keeps illustrating [SPEC.md](SPEC.md).

## Pre-commit hooks

Hooks must pass before a commit is pushed. `task setup` installs them. Run
them all, or one while iterating:

```bash
task lint
```

```bash
pre-commit run <hook-id> --all-files
```

The hooks are defined in [`.pre-commit-config.yaml`](.pre-commit-config.yaml).
Those whose failure needs explaining:

| Hook | Checks | Fix |
| --- | --- | --- |
| `yamllint` | YAML style, per [`.yamllint.yaml`](.yamllint.yaml) | fix the file |
| `no-co-authors` | no `Co-Authored-By:` or `Generated with` line in a commit message; `--all-files` skips it | rewrite the message |
| `jsonnet-format`, `mise-fmt` | Jsonnet and `mise.toml` formatting | fixes itself; re-run |
| `helm-lint` | `charts/therealm-layout`, with `values-lint.yaml` | fix the chart |
| `helm-lint-whoami` | the example's `whoami` chart | fix the chart |
| `helm-docs` | the chart's `README.md` matches its `values.yaml` | fixes itself; commit the regenerated README |
| `trivy-chart` | Kubernetes misconfigurations in the rendered chart | fix the chart |

`--no-verify` and `SKIP=` are not the fix: a red hook is a real finding. If a
rule is wrong for this repository, change its configuration in the same change
and say why. CI runs the same hooks, so skipping them locally only moves the
failure somewhere slower.

## Continuous integration

| Workflow | Purpose | Reproduce locally |
| --- | --- | --- |
| [`quality.yaml`](.github/workflows/quality.yaml) | quality gate: the `lint` and `test` jobs | `task lint`, `task test` |
| [`chart.yaml`](.github/workflows/chart.yaml) | checks a `chart-*` tag against the committed versions, then publishes the chart to `oci://ghcr.io/therealm-tech/charts` | `helm package charts/therealm-layout`; the push has no local equivalent |

Both jobs of `quality.yaml`, `lint` and `test`, are required to merge. CI
installs its tools with mise from the same `mise.lock`. `chart.yaml` never runs
on a pull request, and a manual run on anything but a `chart-*` tag fails.
Neither workflow needs a secret: `chart.yaml` pushes with the `GITHUB_TOKEN`
GitHub provides, granted `packages: write` in its publishing job only.
[Dependabot](.github/dependabot.yaml) keeps the pinned actions and the
pre-commit hook revisions up to date.

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

```bash
scripts/release.sh --dry-run 0.2.0
```

```bash
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
