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

current_branch="$(git branch --show-current)"
dists_label="latest"
if [ "$current_branch" != "main" ] ; then
    dists_label="${current_branch//\//-}"
fi

./build_all_sudo.sh "$current_branch" "$dists_label" 2>&1 | tee_log
