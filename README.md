# layout-spec

The therealm Argo CD repository layout: where the files describing Argo CD
deployments live, and a Helm chart that deploys a repository laid out that way.

## Description

[SPEC.md](SPEC.md) is the specification and the source of truth. It defines a
catalogue of applications (`apps/`), per-environment overrides (`envs/`) and
the actual deployments per cluster (`clusters/`), split between a repo
catalogue and a repo platform, and how their files combine into one deployed
instance.

[`charts/therealm-layout`](charts/therealm-layout) implements it: one release
per cluster renders an Argo CD `ApplicationSet` that turns every instance of
that cluster into an Argo CD `Application`. Its values are documented in
[its README](charts/therealm-layout/README.md).

[`example/`](example/) is a repository following the layout, with both roles
held by the same repository.

The specification covers the layout only: installing Argo CD, synchronising
applications and validating files are outside its scope.

## Getting started

### Prerequisites

- Argo CD ≥ 3.5, with its ApplicationSet controller.
- One Argo CD cluster `Secret` per cluster of the layout, named after its
  directory under `clusters/`.
- A Git repository following [SPEC.md](SPEC.md). Argo CD needs read access to
  it, and to the repo catalogue when that is a different repository.
- [Helm](https://helm.sh/docs/intro/install/) ≥ 3, to render the chart
  locally.

### Installation

```sh
git clone git@github.com:therealm-tech/layout-spec.git
```

### Configuration

The chart reads one cluster's `clusters/<cluster>/cluster.yaml` as a values
file, and its name through the `cluster` value. Every other value is optional;
see [the chart's README](charts/therealm-layout/README.md).

### Usage

Render the ApplicationSet of one cluster of the example:

```sh
helm template root-prod-eu-1 charts/therealm-layout --namespace argocd -f example/clusters/prod-eu-1/cluster.yaml --set cluster=prod-eu-1
```

In a real repository, each Argo CD instance is bootstrapped by one manifest
holding a root `Application` per cluster it manages, which renders this chart
with that cluster's `cluster.yaml`. The example's
[`clusters/mgmt-1/root.yaml`](example/clusters/mgmt-1/root.yaml) is such a
manifest; apply it once:

```sh
kubectl apply -f clusters/mgmt-1/root.yaml
```

Its chart registry, `registry.example.com/charts`, is a placeholder for
wherever the chart is published.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT — see [LICENSE](LICENSE).
