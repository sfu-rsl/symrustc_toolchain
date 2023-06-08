#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euo pipefail

export SYMRUSTC_BRANCH="$1"; shift

unit=G
size=$(echo $(df -B"$unit" --output=avail $(docker info | grep 'Root' | cut -d ':' -f 2) | tail -n 1))

if (( $(echo "$size" | cut -d "$unit" -f 1) < 30 )) ; then
    echo "Error: too low remaining disk space: $size" >&2
    exit 1
fi

function time_docker_build () {
    date -R
    /usr/bin/time -v docker build "$@"
}
export -f time_docker_build

#

function docker_b () {
    time_docker_build --target "$1" -t "belcarra_$1" --build-arg SYMRUSTC_BRANCH="$SYMRUSTC_BRANCH" --build-arg DISTS_TAG="${SYMRUSTC_BRANCH//\//-}" .
}
export -f docker_b

./generated/build.sh

