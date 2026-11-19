#!/usr/bin/env bash
set -euo pipefail

# top-level field of Chart.yaml (name, version)
chart_field() {
  awk -v k="$2" '$1 == k":" { gsub(/"/, "", $2); print $2; exit }' "$1/Chart.yaml"
}

all_charts() {
  find charts -mindepth 2 -maxdepth 2 -name Chart.yaml -printf '%h\n' | sort
}

semver_re='^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$'

validate_chart() {
  local dir=$1 name version
  name=$(chart_field "$dir" name)
  version=$(chart_field "$dir" version)
  if [[ "$name" != "$(basename "$dir")" ]]; then
    echo "::error file=$dir/Chart.yaml::name ($name) must match the directory ($dir)"; return 1
  fi
  if [[ ! "$version" =~ $semver_re ]]; then
    echo "::error file=$dir/Chart.yaml::version ($version) is not semver"; return 1
  fi
  helm lint "$dir" >/dev/null
  helm template "$name" "$dir" >/dev/null
}

tag_exists() {
  git rev-parse -q --verify "refs/tags/$1" >/dev/null
}
