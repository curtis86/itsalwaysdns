#!/usr/bin/env bash

set -o pipefail
set -u

function usage() {
  echo
  echo "Usage:"
  echo "$(basename $0) <domain_name>" >&2
  echo
}
