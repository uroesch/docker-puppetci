#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

declare -ra LINT_CHECKS=(
  --no-140chars-check    # allow lines longer then 80 characters
  --fail-on-warnings     # code should be clean of warnings
)

puppet-lint ${LINT_CHECKS[@]} .
