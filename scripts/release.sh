#!/usr/bin/env bash
set -euo pipefail

chart_dir=charts/therealm-layout
chart_yaml=$chart_dir/Chart.yaml
chart_readme=$chart_dir/README.md
root_yaml=example/clusters/mgmt-1/root.yaml
readme=README.md
chart_ref=oci://ghcr.io/therealm-tech/charts/therealm-layout

usage() {
	cat <<EOF
Usage: scripts/release.sh [--dry-run] <version>

Cut a release of the therealm-layout chart: set its version, regenerate what
derives from it, commit, tag chart-<version>, then ask before pushing. Pushing
the tag is what publishes the chart to ${chart_ref%/*}.

<version> is X.Y.Z, or X.Y.Z-rcN for a pre-release.

A stable release also moves every committed reference to the chart version:
the targetRevision of the root Applications in ${root_yaml},
and the --version of the helm command in ${readme}. A pre-release leaves them
on the last stable version.

When ${chart_yaml} already holds <version>, there is nothing to commit:
HEAD is tagged, once the other references are checked to match.

Options:
  --dry-run   print what would change, the commit and the tag, then stop
  -h, --help  show this help

Examples:
  scripts/release.sh --dry-run 0.2.0
  scripts/release.sh 0.2.0-rc1
  scripts/release.sh 0.2.0
EOF
}

die() {
	printf 'release: %s\n' "$*" >&2
	exit 1
}

chart_version() {
	sed -n 's/^version:[[:space:]]*//p' "$chart_yaml"
}

# The chart sources are the only ones in root.yaml pinned to a version; the git
# sources track a branch.
root_versions() {
	sed -nE 's/^[[:space:]]+targetRevision:[[:space:]]+([0-9][^[:space:]]*)$/\1/p' "$root_yaml"
}

readme_versions() {
	sed -nE "s#.*${chart_ref} --version ([^[:space:]]+).*#\\1#p" "$readme"
}

# Prints each committed reference that does not hold $1, one per line.
stale_references() {
	local v
	for v in $(root_versions); do
		[ "$v" = "$1" ] || printf '  %s: targetRevision %s\n' "$root_yaml" "$v"
	done
	for v in $(readme_versions); do
		[ "$v" = "$1" ] || printf '  %s: --version %s\n' "$readme" "$v"
	done
}

rewrite() {
	local file=$1
	shift
	sed -E "$@" "$file" >"$file.tmp"
	mv "$file.tmp" "$file"
}

dry_run=false
version=
while [ $# -gt 0 ]; do
	case $1 in
	-h | --help)
		usage
		exit 0
		;;
	--dry-run) dry_run=true ;;
	-*) die "unknown option: $1 (see --help)" ;;
	*)
		[ -z "$version" ] || die "expected one version, got '$version' and '$1'"
		version=$1
		;;
	esac
	shift
done

[ -n "$version" ] || {
	usage >&2
	exit 1
}
[[ $version =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-rc[1-9][0-9]*)?$ ]] ||
	die "'$version' is not X.Y.Z or X.Y.Z-rcN; pass the bare version, without 'v' or 'chart-'"

case $version in
*-*)
	stable=false
	kind=pre-release
	;;
*)
	stable=true
	kind=stable
	;;
esac
tag=chart-$version

toplevel=$(git rev-parse --show-toplevel)
cd "$toplevel"

dirty=$(git status --porcelain)
[ -z "$dirty" ] || die "the working tree is not clean; commit or stash first"

git fetch --quiet --tags origin
default_branch=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD) ||
	die "origin/HEAD is not set; run 'git remote set-head origin --auto'"
default_branch=${default_branch#origin/}
branch=$(git symbolic-ref --quiet --short HEAD) || die "HEAD is detached; check out $default_branch"
[ "$branch" = "$default_branch" ] || die "on '$branch'; releases are cut from $default_branch"

behind=$(git rev-list --count "HEAD..origin/$default_branch")
[ "$behind" -eq 0 ] || die "$default_branch is $behind commit(s) behind origin; run 'git pull --ff-only'"

! git rev-parse --quiet --verify "refs/tags/$tag" >/dev/null || die "tag $tag already exists"

[ -n "$(root_versions)" ] || die "no chart targetRevision found in $root_yaml"
[ -n "$(readme_versions)" ] || die "no '$chart_ref --version' command found in $readme"

current=$(chart_version)
[ -n "$current" ] || die "no top-level version in $chart_yaml"

if [ "$current" = "$version" ]; then
	bump=false
	if $stable; then
		stale=$(stale_references "$version")
		[ -z "$stale" ] || die "$chart_yaml already holds $version, but these references do not:
$stale
Bring them to $version in a pull request, then re-run."
	fi
else
	bump=true
	command -v helm-docs >/dev/null || die "helm-docs is not installed; see CONTRIBUTING.md"
fi

subject="release chart $version"

if $dry_run; then
	printf 'chart version: %s -> %s (%s)\n' "$current" "$version" "$kind"
	if $bump; then
		printf 'files:\n  %s\n  %s\n' "$chart_yaml" "$chart_readme"
		if $stable; then
			printf '  %s (targetRevision %s -> %s)\n' "$root_yaml" "$(root_versions | sort -u | paste -sd, -)" "$version"
			printf '  %s (--version %s -> %s)\n' "$readme" "$(readme_versions | sort -u | paste -sd, -)" "$version"
		fi
		printf 'commit: %s\n' "$subject"
		printf 'tag: %s, on the release commit\n' "$tag"
	else
		printf 'commit: none, %s already holds %s\n' "$chart_yaml" "$version"
		printf 'tag: %s, on HEAD (%s)\n' "$tag" "$(git rev-parse --short HEAD)"
	fi
	printf 'dry run: nothing changed\n'
	exit 0
fi

if $bump; then
	rewrite "$chart_yaml" "s/^version:.*$/version: $version/"
	helm-docs --chart-search-root charts
	if $stable; then
		rewrite "$root_yaml" "s/^([[:space:]]+targetRevision:[[:space:]]+)[0-9][^[:space:]]*$/\\1$version/"
		rewrite "$readme" "s#(${chart_ref} --version )[^[:space:]]+#\\1$version#"
	fi

	stale=
	[ "$(chart_version)" = "$version" ] || stale="  $chart_yaml: version $(chart_version)"
	if $stable; then
		stale="$stale$(stale_references "$version")"
	fi
	[ -z "$stale" ] || die "references left behind after the update:
$stale
Restore the tree with 'git checkout -- .' and fix the script."

	git add -- "$chart_yaml" "$chart_readme" "$root_yaml" "$readme"
	git commit --quiet -m "$subject"
	printf 'committed: %s\n' "$subject"
else
	printf '%s already holds %s: nothing to commit, tagging HEAD\n' "$chart_yaml" "$version"
fi

git tag --annotate "$tag" -m "chart $version"
printf 'tagged: %s\n' "$tag"

reply=
if [ -t 0 ]; then
	printf 'push %s and %s to origin? this publishes the release. [y/N] ' "$branch" "$tag"
	read -r reply
else
	printf 'stdin is not a terminal: not pushing\n'
fi

case $reply in
y | Y | yes | YES)
	git push --atomic origin "$branch" "refs/tags/$tag"
	printf 'pushed: the chart workflow publishes %s:%s\n' "$chart_ref" "$version"
	;;
*)
	printf 'not pushed; the commit and tag stay local. to publish:\n  git push --atomic origin %s refs/tags/%s\n' "$branch" "$tag"
	;;
esac
