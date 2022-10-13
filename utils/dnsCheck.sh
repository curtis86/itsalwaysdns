#!/usr/bin/env bash

set -o pipefail
set -u

subdomain=1
lastDnsResultHash=""
sslCheck=0
nsRecordsCheck=0
nameserverPort=53

function dnsCheck() {

  # Populate a list of delegated nameservers from whois information; this has only been tested on common TLDs, this might not work on others.
  OLDIFS=$IFS
  IFS=$'\n'

  if ! delegatedNameservers=($(whois "${domain}" | grep -i '^name server:' | cut -d\: -f2 | tr '[A-Z]' '[a-z]' | sed 's/ //'g | tr -d '\r' | sort | uniq)); then
    # If we dont get any response, this might be a subdomain; check domain authority response for this instead
    # If the SOA authority is the TLD, then this domain check has probably failed!
    if ! parentDomain="$(dig SOA "${domain}" | grep SOA | tail -1 | awk '{ print $1 }' | tr -d '\r' | sed 's/.$//g')" || [[ "${parentDomain}" == "$(echo "${domain}" | awk -F'.' '{ print $NF }')" ]]; then
      msg 2 "Could not determine nameservers."
      msg 2 "  - Domain spelled wrong, not registered or expired"
      msg 2 "  - Ensure that nameservers for the domain are reachable (firewall, routing)"
      msg 2 "  - Ensure that service is running and is binding to the correct interface (eg. public interface, and not loopback only)"
      exit 1
    else
      msg 1 "Could not determine nameservers from WHOIS information, this is possibly a subdomain or a TLD we don't know to process yet!"
      msg 1 "Assuming the parent domain of ${domain} is ${parentDomain} ??"
    fi

    if ! delegatedNameservers=($(whois "${parentDomain}" | grep -i 'name server:' | cut -d\: -f2 | tr '[A-Z]' '[a-z]' | sed 's/ //'g | tr -d '\r')); then
      if ! delegatedNameservers=($(dig +short NS "${parentDomain}" | tr '[A-Z]' '[a-z]' | sed 's/ //'g | tr -d '\r')) || [[ -z "${delegatedNameservers}" ]]; then
        msg 2 "Could not determine nameservers."
        msg 2 "  - Domain spelled wrong, not registered or expired"
        msg 2 "  - Ensure that nameservers for the domain are reachable (firewall, routing)"
        msg 2 "  - Ensure that service is running and is binding to the correct interface (eg. public interface, and not loopback only)"
        exit 1
      else
        msg 1 "Couldnt determine nameservers from whois info; skipping nameserver check."
        nsRecordsCheck=1
      fi
    fi

    # Otherwise, this is not a subdomain
    subdomain=0
  fi

  IFS=$OLDIFS

  # Get nameserver records from nameservers
  if [ ${subdomain} -eq 0 ]; then
    nsRecordDomain="${parentDomain}"
  else
    nsRecordDomain="${domain}"
  fi

  if ! nsRecords=($(dig +short NS "${nsRecordDomain}" | sed 's/^ //g' | tr '[A-Z]' '[a-z]')) || [ ${#nsRecords[@]} -eq 0 ]; then
    msg 2 "Warning: unable to retrieve nameserver records"
    msg 2 "  - Ensure that NS records are created on the nameservers."
  fi

  # Test that each delegated nameserver is able to respond to a SOA request for the domain; if not, assume its not answering queries for this domain...
  # ... and remove it from future checks
  ind=0
  for ns in "${delegatedNameservers[@]}"; do
    if ! _digOutput="$(dig @${ns} +short SOA ${domain})"; then
      echo "Warning: unable to get SOA record for ${domain} from ${ns} removing from future checks."
      unset delegatedNameservers[${ind}]
    fi
    ((ind++))
  done

  if [ "${#delegatedNameservers[@]}" -eq 0 ]; then
    msg 2 "Did not receive a response from any delegated nameserver."
    msg 2 "  - Ensure that nameservers for the domain are reachable (firewall, routing)"
    msg 2 "  - Ensure that service is running and is binding to the correct interface (eg. public interface, and not loopback only)"
    msg 2 "  - Domain could possibly be expired."
    exit 1
  fi

  # Check if delegated nameservers match nameserver records
  delegatedNsHash="$(echo "${delegatedNameservers[@]}" | tr ' ' '\n' | sort)"
  nsRecordsHash="$(echo "${nsRecords[@]%.}" | tr ' ' '\n' | sort)"

  echo
  msg 9 "Got ${#delegatedNameservers[@]} delegated nameservers and ${#nsRecords[@]} nameserver records"

  if [ "${delegatedNsHash[@]}" != "${nsRecordsHash[@]}" ]; then
    msg 1 "Delegated nameserver and nameserver records do not match!"
    msg 1 "  - Ensure that NS records set at the domain registrar and nameserver match"
    msg 1 "Delegated nameservers:"
    echo "${delegatedNsHash[@]}"
    msg 1 "Nameserver records from nameservers:"
    echo "${nsRecordsHash[@]}"
  else
    msg 9 "Delegated nameserver and nameserver records match."
  fi

  echo

  if [ ${#delegatedNameservers[@]} -eq 1 ]; then
    msg 1 "Only 1 nameserver found."
    msg 1 "  - For redundancy, there should be at least 2 nameservers"
  fi

  msg 0 "TCP Check:"
  echo

  if [ ${ignoreDnsTcp} -eq 1 ]; then
    for d in "${delegatedNameservers[@]}"; do
      if portScan "${d}" "${nameserverPort}"; then
        msg 9 "${d} is reachable on TCP/port ${nameserverPort}" >&2
      else
        msg 2 "${d} is NOT reachable on TCP/port ${nameserverPort}" >&2
        msg 2 "  - DNS responses > 512 bytes will be sent over TCP instead of UDP"
      fi
    done
  else
    msg 1 "Skipping TCP scan"
  fi
  echo

  msg 0 "DNS Results:"
  echo

  ind=0
  _allDnsRecords=""
  _digOutput=""
  _lastDnsResultHash=""
  declare -a _dnsResults

  # Begin DNS check, targeted at each recursive resolver to each nameserver
  # TODO: separate answer aand metadata; some metadata needs to be assessed for appropriate response..
  for r in "${dnsResolvers[@]}"; do
    for ns in "${delegatedNameservers[@]}"; do
      set +ux
      if ! _digOutput=($(dig @${r} @${ns} +short "${domain}" 2>&1 | sort)) || [ -z "${_digOutput}" ] || [[ "${#_digOutput[@]}" -eq 0 ]]; then
        set -u
        msg 2 "-> ${r} --> ${ns} ---> ${domain} (A): "
        msg 2 "No result"
        _dnsResults[${ind}]="${r},${ns},none"
        continue
      else
        msg 9 "-> ${r} --> ${ns} ---> ${domain} (A): "
        for d in "${_digOutput[@]}"; do
          msg 9 "${d}"
          _allDnsRecords="${_allDnsRecords}\n${d}"
          _dnsResults[${ind}]="${r},${ns},${d}"
        done
        dnsResultHash="$(echo "${_digOutput[@]}" | openssl dgst -sha256 | awk '{ print $NF }')"

        if [ -z "${_lastDnsResultHash}" ]; then
          _lastDnsResultHash="${dnsResultHash}"
          msg 9 "Dns result hash: ${dnsResultHash}"
        else
          if [ "${dnsResultHash}" == "${_lastDnsResultHash}" ]; then
            msg 9 "DNS result hash: ${dnsResultHash}"
          else
            msg 2 "Dns result hash: ${dnsResultHash}"
          fi
          _lastDnsResultHash="${dnsResultHash}"
        fi

        ((ind++))
      fi
      echo
    done
  done

  msg 0 "SSL fingerprints:"

  allDnsRecords=($(echo -e "${_allDnsRecords}" | sort | uniq))

  if [ ${sslCheck} -eq 0 ]; then
    if [ ${#allDnsRecords[@]} -ge 1 ]; then
      for d in "${allDnsRecords[@]}"; do
        if _sslCheck="$(sslCheck "${d}")"; then
          msg 9 "${d} has ${_sslCheck}"
        else
          msg 2 "${d}: unable to determine fingerprint"
        fi
      done
    fi
  fi
}
