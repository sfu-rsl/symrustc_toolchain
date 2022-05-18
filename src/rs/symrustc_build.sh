#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euxo pipefail

source $SYMRUSTC_HOME_RS/wait_all.sh

export SYMRUSTC_TARGET_NAME=symrustc/build
export SYMRUSTC_EXAMPLE="$1"; shift
concolic_rustc="$1"; shift

#

if eval $concolic_rustc
   # TODO: at the time of writing, examples having several Rust source files (e.g. comprising build.rs) are not yet implemented
then
    export SYMRUSTC_INPUT_FILE="$SYMRUSTC_EXAMPLE/src/main.rs"

    CARGO_TARGET_DIR=target_rustc_none_on fork $SYMRUSTC_HOME_RS/rustc_none.sh -C passes=symcc -lSymRuntime "$@"
    CARGO_TARGET_DIR=target_rustc_none_off fork $SYMRUSTC_HOME_RS/rustc_none.sh "$@"
    CARGO_TARGET_DIR=target_rustc_file_on fork $SYMRUSTC_HOME_RS/rustc_file.sh -C passes=symcc -lSymRuntime "$@"
    CARGO_TARGET_DIR=target_rustc_file_off fork $SYMRUSTC_HOME_RS/rustc_file.sh "$@"
    CARGO_TARGET_DIR=target_rustc_stdin_on fork $SYMRUSTC_HOME_RS/rustc_stdin.sh -C passes=symcc -lSymRuntime "$@"
    CARGO_TARGET_DIR=target_rustc_stdin_off fork $SYMRUSTC_HOME_RS/rustc_stdin.sh "$@"
fi

fork $SYMRUSTC_HOME_RS/cargo.sh rustc --manifest-path "$SYMRUSTC_EXAMPLE/Cargo.toml" "$@"

wait_all

#

if [[ ! -v SYMRUSTC_HIDE_RESULT ]]; then
    source $SYMRUSTC_HOME_RS/symrustc_build_show.sh
fi