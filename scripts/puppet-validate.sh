#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# Setup
# -----------------------------------------------------------------------------
set +o xtrace
set -o pipefail
set -o errexit
set -o nounset

# -----------------------------------------------------------------------------
# Globals
# -----------------------------------------------------------------------------
declare -r SCRIPT=${0##*/};
declare -r VERSION="0.4.0"
declare -r LICENSE="MIT"
declare -r AUTHOR="Urs Roesch"
declare -g MODE=puppet
declare -a PUPPET_FILES=();
declare -r JSON_FORMAT='
{
  "%s": {
    "issue_code": "%s",
    "message": "%s",
    "full_message": "%s",
    "file": "%s",
    "line": %d,
    "pos": %d
  }
}
'

# -----------------------------------------------------------------------------
# Functions
# -----------------------------------------------------------------------------
function usage() {
  echo exit_code=${1:-1}
  cat << USAGE
    Usage:
      ${SCRIPT} <options>

    Options:
      -h | --help        This message
      -m | --mode <mode> Use mode puppet for .pp file aka manifests or
                         .epp for template files.
      -V | --version     Print version information and exit.

    Summary:
      Wrapper script around 'puppet parser' and 'puppet epp' validators for
      files changed in the last commit.

    Usage:
      GitLab CI/CD:

        # gitlab-ci.yml
        ---
        stages:
          - validate
        .validate:
          stage: validate
          script:
            - /usr/local/bin/puppet-validate.sh -m \${PUPPET_VALIDATOR}

        validate:puppet:
          extends: .validator
          variables:
            PUPPET_VALIDATOR: puppet

        validate:epp:
          variables:
            PUPPET_VALIDATOR: epp

USAGE
  echo ${exit_code}
}

function parse_options() {
  while (( ${#} > 0 )); do
    case ${1} in
    -h|--help) usage 0;;
    -m|--mode) shift; MODE=${1};;
    -V|--version) version;;
    esac
    shift
  done
}

function version() {
  printf "%s v%s\nCopyright (c) %s\nLicense - %s\n" \
    "${SCRIPT}" "${VERSION}" "${AUTHOR}" "${LICENSE}"
  exit 0
}

function find_files() {
  local -- pattern=${1:-'\.pp$'}; shift
  for pp in $(git log --name-only -n 1 --pretty=format: | grep ${pattern}); do
    [[ -f ${pp} ]] && PUPPET_FILES+=( "${pp}" ) || :
  done
}

function validate_files() {
  local -i exit_code=0
  (( ${#PUPPET_FILES[@]} == 0 )) && exit 0 || :
  for file in ${PUPPET_FILES[@]}; do
    case ${file} in
    *.epp) epp::validate "${file}" || exit_code+=$?;;
    *pp)   puppet parser validate --render-as json "${file}" || exit_code+=$?;;
    esac
  done
  exit ${exit_code}
}

function strip-color() {
  sed -r 's/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g'
}

function main() {
  case ${MODE} in
  puppet) find_files '\.pp$'  ;;
  epp)    find_files '\.epp$' ;;
  esac
  validate_files
}

# -----------------------------------------------------------------------------
# EPP Functions
# -----------------------------------------------------------------------------
# the --render-as json option is not working hence we have to roll our own :(
# -----------------------------------------------------------------------------

function epp::validate() {
  local -- file=${1}; shift;
  readarray -t output <<< $(puppet epp validate "${file}" 2>&1 | strip-color)
  [[ -z ${output[0]:-} ]] && return 0
  epp::to_json "${output[0]}"
  return 1
}

function epp::to_json() {
  local full_message=${1}; shift;
  IFS="[:,()]" read -a parts <<< ${full_message}
  local -i line=${parts[-3]}
  local -i pos=${parts[-1]}
  local -- message="${parts[1]/# /}"
  local -- issue_code="${parts[0]}"
  local -- file=${parts[-5]/# /}

  printf "${JSON_FORMAT}" \
    "${file}" \
    "${issue_code^^}" \
    "${message}" \
    "${full_message}" \
    "$(pwd)/${file}" \
    ${line} \
    ${pos}
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
parse_options "${@}"
main
