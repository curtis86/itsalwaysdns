#!/usr/bin/env bash

set -o pipefail
set -u

# Expected:
# MSG_CODE "MESSAGE"
# Codes:
# 0 - Notice
# 1 - Warning
# 2 - Error
# 9 - OK
# * - Unknown

# Text colours
txtBold=$(tput bold)
txtRed=$(tput setaf 1)
txtYellow=$(tput setaf 3)
txtGreen=$(tput setaf 2)
txtNormal=$(tput sgr0)

function msg() {
  MSG_CODE="$1"
  shift
  dateNow="$(date)"

  case "${MSG_CODE}" in
  0) echo -e "${txtBold}$@${txtNormal}" ;;
  1) echo -e "${txtBold}${txtYellow}[-]  ${txtNormal}$@" >&2 ;;
  2) echo -e "${txtBold}${txtRed}[!]  ${txtNormal}$@" >&2 ;;
  9) echo -e "${txtBold}${txtGreen}[+]  $@${txtNormal}" >&2 ;;
  *) echo -e "${txtBold}${txtYellow}[!] ${txtNormal}$@" >&2 ;;
  esac
}
