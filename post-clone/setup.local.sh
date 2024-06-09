#!/bin/bash

[ "${BASH_SOURCE[0]}" -ef "$0" ] && echo "$(basename "$0") | ERROR: This file must be sourced" && exit 1

function pcslocError() {
  local msgPrefix="setup-local"
  if [ $# -gt 1 ]
  then
    msgPrefix="${msgPrefix} | $1"
    shift
  fi
  pcsError "${msgPrefix}" "$@"
  exit 1
}

echo ""
echo "---[ $(dirname "$(realpath "${SCRIPT_DIR}")") ]---"
echo "---| post-clone/$(basename "${BASH_SOURCE[0]}")"

[ -z "${WORKSPACE_BASE_LIB_SH}" ] && pcslocError "WORKSPACE_BASE_LIB_SH not defined\n" && exit 1
[ -z "${POST_CLONE_SETUP_LIB_SH}" ] && pcslocError "POST_CLONE_SETUP_LIB_SH not defined"
[ -z "${POST_CLONE_LIB_SH}" ] && pcslocError "POST_CLONE_LIB_SH not defined"

#---[ setup-local ]---

function service_setup() {
  local zTarget="$1" && shift

  if [ -n "${zTarget}" ] && [ -d "../${zTarget}" ]
  then
    echo ":: ${zTarget}"
    while [ -n "${zTarget}" ]
    do
      if [ "${zTarget:0:4}" == 'raw:' ]
      then
        sed -i "${zTarget:4}" "${ENV_FILE}"
      else
        local target="$(echo "${zTarget}" | sed 's|/|\\/|g')"
        sed -i "s/^#${target}\$/${target}/g" "${ENV_FILE}"
      fi

      local zTarget="$1"
      shift
    done
    unset _dummy_
  fi
}

ENV_FILE="workspace.env.sh"

#-- template
templateFile "${ENV_FILE}"

#-- mode

echo ""
SETMODE_SHOW_TARGET="TRUE"
setMode "iptables-config.sh" "775"
setMode "workspace.sh" "775"

[ ! -f "../workspace" ] && ln -s "$(basename $(pwd))/workspace.sh" ../workspace

#-- services

echo ""
service_setup 'services'
