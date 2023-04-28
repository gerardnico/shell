#!/usr/bin/env bash

## Cli Example

CLI_NAME=$(basename "$0") # Name of the cli

# Print the error message $1
function echo_err() {
  RED='\033[0;31m'
  NC='\033[0m' # No Color
  #(>&2 echo -e "${RED}$1${NC}")
  echo_log "${RED}$1${NC}"
}

# Send the message to the log file and the stdout
#
# The log file can be given via the first arg $2
# Default to the variable ${LOG_FILE}
function echo_log() {

  LOCAL_LOG_FILE_PATH=${LOG_FILE}
  if ! ([ -z ${2+x} ]); then
    LOCAL_LOG_FILE_PATH=$2
  fi
  MESSAGE=$1
  echo -e "$MESSAGE" 2>&1 | tee -a ${LOCAL_LOG_FILE_PATH}

}

# Takes the exit status as variable
#
# Example:
#     close_script 1
# will:
#    exit with the value 1
#
close_script() {

  echo_log ""
  END_DATE=$(date -u +"%Y-%m-%d_%H:%M:%S")
  echo_log "Ended at $END_DATE"
  echo_log "See log at $LOG_FILE"
  echo_log "See artifacts at $RUN_DIR"

  # Exit if we have a exit status as first argument
  if ! ([ -z ${1+x} ]); then
    exit $1
  fi

}

# Check the command $1
function check_command() {
  command -v "$1" -v >/dev/null || {
    echo >&2 "I require $1 but it's not installed.  Aborting."
    close_script 1
  }
}

function print_usage() {

  echo ""
  echo "Usage of the cli ${CLI_NAME}"
  echo ""
  echo "   ${CLI_NAME} command"
  echo ""
  echo "where command is one of:"
  echo "     * echo - echo the argument"

  echo ""

}

hello_module() {

  # Prerequisites
  check_command echo

  COMMAND=$1
  shift
  ARG=$*

  case ${COMMAND} in
  'world')
    echo "Hello world (${ARG})"
    ;;
  'help')
    echo "Help on the module ${MODULE}"
    echo ""
    echo "Syntax:"
    echo "   ${CLI_NAME} ${MODULE} command"
    echo ""
    echo "where command may be:"
    echo "  * echo - Echo your name"
    echo "  * help - This message"
    ;;
  *)
    echo_err "A command is mandatory"
    hello_module help
    close_script 1
    ;;
  esac
}

# Main

# Runtime
FILE_NAME=$(basename $0)
CLI_NAME=${FILE_NAME%.*} # Name of the cli
# No : for the RUN DATE as this is not supported by infacmd
RUN_DATE=$(date -u +"%Y-%m-%d.%H-%M-%S")
RUN_DIR="${HOME}/${CLI_NAME}/${RUN_DATE}"
mkdir -p ${RUN_DIR}
LOG_FILE="$RUN_DIR/log_${RUN_DATE}.txt"
touch ${LOG_FILE}
# shellcheck disable=SC2034
HOME_PATH=$(
  cd "$(dirname "$0")" || exit 1
  pwd -P
)

echo_log "Start script ${CLI_NAME} at $RUN_DATE"
echo_log ""

MODULE=$1
shift

case ${MODULE} in
hello)
  # $@ preserve from word splitting
  hello_module "$@"
  ;;
*)
  echo_err "Module (${MODULE}) is unknown."
  print_usage
  close_script 1
  ;;
esac

close_script
