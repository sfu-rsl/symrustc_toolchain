#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euo pipefail

hash="$(git log -1 --pretty=format:%H)"
name="$(basename $PWD)_log_${hash}__"

fic="../$name$(date '+%F_%T' | tr -d ':-')"

function tee_log () {
    if [ ! -f "$fic" ] ; then
        tee "$fic"
        date -R >> "$fic"
    else
        exit 1
    fi
}

#

./build_all_sudo.sh "$(git branch --show-current)" "latest" 2>&1 | tee_log
