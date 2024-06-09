#!/bin/bash

function iptError() {
  local msgPrefix="uptabes-config"
  if [ $# -gt 1 ]
  then
    msgPrefix="${msgPrefix} | $1"
    shift
  fi
  if [[ $(type -t wsError) == function ]]
  then
    wsError "${msgPrefix}" "$@"
  else
    echo ""
    echo "${msgPrefix} | ERROR: $@"
    echo ""
  fi
  exit 1
}

[ "$(id -u)" -eq 0 ] || iptError "This script must be executed as root"

WORKSPACE_HOME_DIR=$(dirname "$0")
WORKSPACE_HOME_DIR=$(cd "${WORKSPACE_HOME_DIR}" && pwd)
WORKSPACE_DIR=$(dirname "${WORKSPACE_HOME_DIR}")
START_DIR=$(pwd)

sourceFile="${WORKSPACE_HOME_DIR}/workspace.env.sh"
[ -f "${sourceFile}" ] || iptError "File not found, ${sourceFile}"
source "${sourceFile}"
[ $? -eq 0 ] || iptError "Failed to source file, ${sourceFile}"


function addRule() {
  local zChain="$1" && shift
  local zProto="$1" && shift
  local zPort="$1" && shift
  local zTarget="$1" && shift
  local zId="$1" && shift

  local suffix=""
  [ -z "${suffix}" ] && [ "${zChain:0:1}" == "#" ] && local suffix="ignorado"
  [ -z "${suffix}" ] && [ -z "${zChain}" ] && local suffix="zChain"
  [ -z "${suffix}" ] && [ -z "${zProto}" ] && local suffix="zProto"
  [ -z "${suffix}" ] && [ -z "${zPort}" ] && local suffix="zPort"
  [ -z "${suffix}" ] && [ -z "${zTarget}" ] && local suffix="zTarget"
  [ -z "${suffix}" ] && [ -z "${zId}" ] && local suffix="zId"
  [ -n "${suffix}" ] && [ "${suffix}" != "ignored" ] && local suffix="! failed, ${suffix} not supplied"

  if [ -z "${suffix}" ]
  then
    iptables --list ${zChain} | grep "/\* ${zId} \*/" &> /dev/null
    if [ $? -eq 0 ]
    then
      local suffix="rule already exists"
    else
      iptables -I ${zChain} -p ${zProto} --dport ${zPort} -j ${zTarget} -m comment --comment "${zId}"
      if [ $? -eq 0 ]
      then
        local suffix="rule added"
      else
        local suffix=" ! failed to add rule"
      fi
    fi
  fi
  echo "chain: ${zChain}, proto: ${zProto}, port: ${zPort}, target: ${zTarget}, id: ${zId} :: ${suffix}"
}

echo ""
echo "---[ workspace-iptables ]---"

if [ "${IPTABLES_CONFIG^^}" != "TRUE" ]
then
  echo "IPTABLES_CONFIG : FALSE"
  exit 0
fi

for rule in ${IPTABLES_RULES}
do
  if [ -n "${rule}" ]
  then
    addRule \
      "$(echo "${rule}" | cut -d: -f1)" \
      "$(echo "${rule}" | cut -d: -f2)" \
      "$(echo "${rule}" | cut -d: -f3)" \
      "$(echo "${rule}" | cut -d: -f4)" \
      "$(echo "${rule}" | cut -d: -f5)"
  fi
done

echo ""
