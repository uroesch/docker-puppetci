#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

find . -type f -name "*.pp" | \
  xargs puppet parser validate --debug
