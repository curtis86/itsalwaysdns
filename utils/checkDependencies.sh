#!/usr/bin/env bash

set -o pipefail
set -u

# Expects an array of ${deps[@]} to be defined

function checkDependencies() {
  for d in "${deps[@]}"; do
    if ! which "${d}" >/dev/null 2>&1; then
      echo "${d} not found" >&2
      return 1
    fi
  done
}
