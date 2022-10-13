#!/usr/bin/env bash

set -o pipefail
set -u

function sslCheck() {

  serverAddress="$1"

  local certOutput
  local sslThumbprint
  local sslExpiryDate
  local sslCommonName

  if certOutput="$(openssl s_client -servername "${domain}" -connect "${serverAddress}":443 <<<"Q" 2>&1)"; then
    if sslThumbprint="$(echo "${certOutput}" | openssl x509 -sha256 -fingerprint -noout | sed 's/\://g' | tr '[A-Z]' '[a-z]' | cut -d\= -f2)"; then
      sslCommonName="$(echo "${certOutput}" | openssl x509 -noout -subject 2>&1 | grep 'subject=' | awk '{ print $NF }' | cut -d\= -f2)"
      sslExpiryDate="$(echo "${certOutput}" | openssl x509 -noout -enddate | cut -d\= -f2)"
      echo "${sslThumbprint} (CN: ${sslCommonName}, Expiry: ${sslExpiryDate})"
    else
      echo "Unknown" >&2
      return 1
    fi
  else
    return 1
  fi
}
