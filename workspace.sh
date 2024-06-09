#!/bin/bash

WORKSPACE_HOME_DIR="$(dirname "$(realpath "$0")")"
WORKSPACE_HOME_DIR="$(cd "${WORKSPACE_HOME_DIR}" && pwd)"
WORKSPACE_DIR="$(dirname "${WORKSPACE_HOME_DIR}")"
START_DIR="$(pwd)"

libFile="${WORKSPACE_HOME_DIR}/.workspace-lib/base.lib.sh"
[ ! -f "${libFile}" ] && echo -e "\nworkspace | ERRR: File not found, ${libFile}\n" && exit 1
source "${libFile}"
[ $? -ne 0 ] && echo "\nworkspace | ERROR: Failed to source file, ${libFile}\n" && exit 1

wsSourceFile "${WORKSPACE_HOME_DIR}/workspace.env.sh"

function actionError() {
  local msgPrefix="action_${pAction}"
  if [ $# -gt 1 ]
  then
    msgPrefix="${msgPrefix} | $1"
    shift
  fi
  wsError "${msgPrefix}" "$@"
  exit 1
}


function item_sail() {
  local zItem="$1" && shift
  echo ""
  if [ "${zItem:0:1}" == "#" ]
  then
    echo ":: ${zItem} - ignored"
    return
  fi

  echo ":: ${zItem}"

  [ ! -d "${zItem}" ] && echo "   path not found" && return
  [ ! -f "${zItem}/sail/sail" ] && echo "   sail not found" && return

  "${zItem}/sail/sail" $@
}


function on_action_trigger() {
  local zPhase="$1" && shift

  [ -z "${zPhase}" ] && wsError "on_action_trigger(${pAction})" "Parameter not supplied, zPhase"

  local trigger_var="ACTION_${pActionId^^}_${zPhase^^}"
  local trigger_list="${!trigger_var}"

  [ -z "${trigger_list}" ] && return

  echo ""
  echo "---[ action_${pActionId} :: ${zPhase} ]---"

  IFS=$'\n'
  local item=""
  for item in ${trigger_list}
  do
    echo ""
    if [ "${item:0:1}" == "#" ]
    then
      echo "ignored : ${item}"
    else
      local item="$(echo "${item}" | sed "s|{{ENVIRONMENT}}|${ENVIRONEMT}|g; s|{{WORKSPACE_DIR}}|${WORKSPACE_DIR}|g")"
      echo ":: ${item}"
      bash -c "${item}"
      #cd "${WORKSPACE_DIR}"
    fi
  done
  unset IFS
}


function action_build() {
  echo ""
  echo "---[ action_${pActionId} ]---"
  local bakAction="${pAction}"

  wsSourceFile "${WORKSPACE_HOME_DIR}/.workspace-lib/git-repo/git-repo.lib.sh"
  GIT_BASE_DIR="${WORKSPACE_DIR}"
  pAction="clone"
  pPostClone="--post-clone"
  pEnvironment="${ENVIRONMENT}"
  gitAction

  pAction="${bakAction}"
}


function action_down() {
  echo ""
  echo "---[ action_${pActionId} ]---"
  IFS=$'\n'
  for item in ${SAIL_LIST}
  do
    item_sail "${item}" down
  done
  unset IFS
}


function action_up() {
  if [ "${IPTABLES_CONFIG^^}" == "TRUE" ]
  then
    echo "Get SUDO access"
    sudo ls > /dev/null
    [ $? -ne 0 ] && actionError "Failed to get SUDO access"
    sudo ${WORKSPACE_HOME_DIR}/iptables-config.sh
  else
    echo ""
  fi
  echo "---[ action_${pActionId} ]---"
  
  IFS=$'\n'
  for item in ${SAIL_LIST}
  do
    item_sail "${item}" up -d
  done
  unset IFS
}


function action_git_pull() {
  echo ""
  echo "---[ action_${pActionId} ]---"
  ${WORKSPACE_HOME_DIR}/git-repo pull

  local bakAction="${pAction}"
  wsSourceFile "${WORKSPACE_HOME_DIR}/.workspace-lib/git-repo/git-repo.lib.sh"
  GIT_BASE_DIR="${WORKSPACE_DIR}"
  pAction="pull"
  pPostClone=""
  pEnvironment="${ENVIRONMENT}"
  gitAction
  pAction="${bakAction}"
}


function action_git_status() {
  echo ""
  echo "---[ action_${pActionId} ]---"
  ${WORKSPACE_HOME_DIR}/git-repo status

  local bakAction="${pAction}"
  wsSourceFile "${WORKSPACE_HOME_DIR}/.workspace-lib/git-repo/git-repo.lib.sh"
  GIT_BASE_DIR="${WORKSPACE_DIR}"
  pAction="pull"
  pPostClone=""
  pEnvironment="${ENVIRONMENT}"
  gitAction
  pAction="${bakAction}"
}


function hosts_file() {
  local zFile="$1" && shift
  [ -z "${zFile}" ] && wsError "hosts_file" "Parameter not supplied, zFile"
  [ ! -f "${zFile}" ] && wsError "hosts_file" "File not found, ${zFile}"

  local tmpFile="$(mktemp)"
  cat "${zFile}" \
    | sed '/#-- docker.internal/d' \
    | sed '/[[:blank:]]host.docker.internal[[:blank:]]*$/d' \
    | sed '/[[:blank:]]gateway.docker.internal[[:blank:]]*$/d' \
    > "${tmpFile}"

  echo -n "
#-- docker.internal
${WORKSPACE_IF_HOST_IP}  host.docker.internal
${WORKSPACE_IF_DOCKER_IP}  gateway.docker.internal
" >> "${tmpFile}"

  WORKSPACE_HOSTS_FILE="$(mktemp)"
  cat -s "${tmpFile}" > "${WORKSPACE_HOSTS_FILE}"
  rm "${tmpFile}"
}

function action_hosts() {
  [ -z "${WORKSPACE_IF_HOST}" ] && actionError "WORKSPACE_IF_HOST not supplied"
  WORKSPACE_IF_HOST_IP="$(ip address show dev ${WORKSPACE_IF_HOST} | grep 'inet ' | sed 's/[[:blank:]]*inet[[:blank:]]*//g' | cut -d'/' -f 1)"
  [ -z "${WORKSPACE_IF_HOST_IP}" ] && actionError "Unable to get IP from: ${WORKSPACE_IF_HOST}"

  [ -z "${WORKSPACE_IF_DOCKER}" ] && actionError "WORKSPACE_IF_DOCKER not supplied"
  WORKSPACE_IF_DOCKER_IP="$(ip address show dev ${WORKSPACE_IF_DOCKER} | grep 'inet ' | sed 's/[[:blank:]]*inet[[:blank:]]*//g' | cut -d'/' -f 1)"
  [ -z "${WORKSPACE_IF_DOCKER_IP}" ] && actionError "Unable to get IP from: ${WORKSPACE_IF_DOCKER}"

  service docker status &> /dev/null || service docker start
  [ $? -ne 0 ] && actionError "Failed to certify docker service"

  hosts_file "/etc/hosts"
  cat -s "${WORKSPACE_HOSTS_FILE}" | sudo tee /etc/hosts > /dev/null
  rm "${WORKSPACE_HOSTS_FILE}"
  unset WORKSPACE_HOSTS_FILE

  if grep -q microsoft /proc/version
  then
    local winHostsFile="$(wslpath -u $(cmd.exe /c echo "%WINDIR%/System32/drivers/etc/hosts") | tr -d '\r\n\000')"
    [ ! -f "${winHostsFile}" ] && actionError "File not found, ${winHostFile}"
    local winHostsFileWsl="$(mktemp)"
    cp "${winHostsFile}" "${winHostsFileWsl}"
    dos2unix "${winHostsFileWsl}"
    hosts_file "${winHostsFileWsl}"
    rm "${winHostsFileWsl}"

    [ ! -d "${WORKSPACE_DIR}/temp" ] && mkdir "${WORKSPACE_DIR}/temp"
    mv "${WORKSPACE_HOSTS_FILE}" "${WORKSPACE_DIR}/temp/windows-etc-hosts"
    unix2dos "${WORKSPACE_DIR}/temp/windows-etc-hosts"
  fi
}


function action() {
  case "${pAction}" in
    'build' | 'down' | 'hosts' | 'up' | 'git-pull' | 'git-status')
      [ "${pAction}" == 'up' ] && action_hosts
      on_action_trigger "before"
      action_${pActionId} $@
      on_action_trigger "after"
    ;;
    'help' | '--help')
      script=$(basename "$0")
      echo "
${script}: Workspace CLI

Use: ${script} <action>

Actions:

  build       Build workspace service images
  down        Stop and remove workspace services
  git-pull    update (git pull) workspace repositories
  git-status  Check (git status) workspace repositories
  up          Start workspace services
  help        Show this help
"
      exit 0
    ;;
    *)
      wsError "Invalid action or not supplied, '${pAction}'"
    ;;
  esac
}


cd "${WORKSPACE_DIR}"

pAction="$1"
pActionId="$(echo -n "${pAction}" | sed 's/[\ \-]/_/g')"
shift

action

echo ""
cd "${START_DIR}"
