#!/usr/bin/env bash
# validates the charts changed since <base>: lint, template and that the version was bumped
# usage: scripts/check-charts.sh origin/main
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/lib.sh

base=${1:?usage: check-charts.sh <base-ref>}
git fetch -q --tags origin 2>/dev/null || true

changed=$(git diff --name-only "$base"...HEAD -- charts | cut -d/ -f1-2 | sort -u)
fail=0
for dir in $changed; do
  [[ -f "$dir/Chart.yaml" ]] || continue
  name=$(chart_field "$dir" name); version=$(chart_field "$dir" version); tag="$name-$version"
  echo "==> $dir ($tag)"
  validate_chart "$dir" || { fail=1; continue; }
  if tag_exists "$tag"; then
    echo "::error file=$dir/Chart.yaml::tag $tag already exists, bump version in Chart.yaml"
    fail=1
  fi
done
exit $fail
