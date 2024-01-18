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
declare -r  SCRIPT=${0##*/};
declare -r  VERSION="0.3.0"
declare -r  LICENSE="MIT"
declare -r  AUTHOR="Urs Roesch"
declare -ga PP_FILES=();
declare -ra ONLY_CHECKS=(
  hard_tabs
  trailing_whitespace
  only_variable_string
)

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
      -V | --version     Print version information and exit.

    Summary:
      Puppet Lint wrapper to check only the files that have
      changed within the last commit.

    Usage:

     GitLab CI/CD:

        # gitlab-ci.yml
        ---
        stages:
          - compliance
        puppet_lint:
          stage: compliance
        tags:
          - puppet
        script: /usr/local/bin/puppet-lint.sh

USAGE
  echo ${exit_code}
}

function parse_options() {
  while (( ${#} > 0 )); do
    case ${1} in
    -h|--help) usage 0;;
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

function only_checks() {
  printf -v only_checks "%s," ${ONLY_CHECKS[@]}
  printf ${only_checks%%,}
}

function pp_files() {
  for pp in $(git log --name-only -n 1 --pretty=format: | grep '\.pp$'); do
    [[ -f ${pp} ]] && PP_FILES+=( "${pp}" ) || :
  done
}

function lint_files() {
  local -i exit_code=0
  (( ${#PP_FILES[@]} == 0 )) && exit 0 || :
  for pp in ${PP_FILES[@]}; do
    ~/bin/puppet-lint \
      --fail-on-warnings \
      --only-checks $(only_checks) \
      "${pp}" || \
      exit_code+=$?;
  done
  exit ${exit_code}
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
parse_options "${@}"
pp_files
lint_files
