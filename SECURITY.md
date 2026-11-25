# Security policy

## Reporting a vulnerability

Report a vulnerability privately, through
[GitHub's private vulnerability reporting](https://github.com/therealm-tech/layout-spec/security/advisories/new).
The report opens a draft advisory that only the maintainers and you can see.

Never report one in a public issue, pull request or discussion: a
vulnerability described in public is disclosed before it is fixed.

A useful report holds:

- the affected chart version, or the section of [SPEC.md](SPEC.md);
- the steps to reproduce, such as the repository files and the chart values
  that trigger it;
- the impact as you see it.

## Supported versions

The chart's fixes ship in a new chart release; only the latest release is
supported. For the specification, the default branch is the only supported
version.

## Scope

In scope:

- the `therealm-layout` chart, in [`charts/therealm-layout`](charts/therealm-layout)
  and as published to `oci://ghcr.io/therealm-tech/charts/therealm-layout`:
  an `ApplicationSet` it renders that lets a repository reach beyond what the
  specification grants it, such as deploying to a cluster other than the
  release's, or that evaluates repository content as a template;
- [SPEC.md](SPEC.md): a rule that grants a repository more control than its
  [Security Considerations](SPEC.md#11-security-considerations) state.

Out of scope:

- the trust the specification grants by design: write access to the repo
  catalogue or the repo platform at a revision a cluster reads is write access
  to that cluster, as its
  [Security Considerations](SPEC.md#11-security-considerations) state;
- [`example/`](example/), which illustrates the layout and is not meant to be
  deployed as it stands;
- [`trlctl`](https://github.com/therealm-tech/trlctl), and Argo CD itself:
  report those in their own repositories;
- a vulnerability in a dependency, already public upstream: report it there,
  and the automated dependency updates bring the fix in;
- a finding that needs an already-compromised host, cluster or account;
- scanner output with no path to exploitation.

## What happens next

Reports are handled on a best-effort basis:

1. The report is acknowledged in the draft advisory.
2. The maintainers assess it with you.
3. The fix is prepared in the advisory's private fork.
4. A chart release, or a change to the specification, ships the fix.
5. The advisory is published, with a CVE requested through GitHub when the
   impact warrants one, and you are credited unless you prefer otherwise.
