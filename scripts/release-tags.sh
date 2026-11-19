#!/usr/bin/env bash
# tags <chart>-<version> on the current commit for every chart whose version has no tag yet.
# Runs on merge to main. DRY_RUN=1 only prints what it would do
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/lib.sh

git fetch -q --tags origin 2>/dev/null || true
fail=0
for dir in $(all_charts); do
  name=$(chart_field "$dir" name); version=$(chart_field "$dir" version); tag="$name-$version"
  if tag_exists "$tag"; then
    # same version, different content = someone changed the chart without bumping it
    if ! git diff --quiet "$tag" HEAD -- "$dir"; then
      echo "::error file=$dir/Chart.yaml::$dir changed since $tag without a version bump"
      fail=1
    fi
    continue
  fi
  validate_chart "$dir"
  if [[ "${DRY_RUN:-0}" == 1 ]]; then
    echo "would create $tag on $(git rev-parse --short HEAD)"
  else
    git tag -a "$tag" -m "$name $version"
    git push origin "refs/tags/$tag"
    echo "created $tag"
  fi
done
exit $fail
