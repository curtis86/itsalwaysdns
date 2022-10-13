#!/usr/bin/env bash

# Expects ${domain} ${port}

# dns server reachability
# port 80 reachability
# port 443 reachability

set -o pipefail
set -u

function portScan() {
  if nc -w ${portScanTimeout} "$1" "$2" <<<"Q" >/dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}
