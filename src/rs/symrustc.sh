#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euo pipefail

if [[ ! -v SYMRUSTC_DIR ]] ; then
    export SYMRUSTC_DIR="$PWD"
fi

if [[ ! -v CARGO_TARGET_DIR ]] ; then
    export CARGO_TARGET_DIR="target_sym"
fi

rustc_input_file="$1"; shift

target="$SYMRUSTC_DIR/$CARGO_TARGET_DIR"
target_d="$target/debug"
target_d_d="$target_d/deps"

#

mkdir -p "$target_d_d"

#

metadata=b4b070263fc6e28b
rustc_exit_code=0

LD_LIBRARY_PATH="$target_d_d:$LD_LIBRARY_PATH:$SYMRUSTC_LD_LIBRARY_PATH" \
\
$SYMRUSTC_RUSTC \
  --crate-name belcarra \
  --edition=2018 \
  "$rustc_input_file" \
  --emit=dep-info,link \
  -C metadata=$metadata \
  -C extra-filename=-$metadata \
  --out-dir "$target_d_d" \
  -C incremental="$target_d/incremental" \
  -L dependency="$target_d_d" \
  -L$SYMRUSTC_RUNTIME_DIR \
  -Clink-arg=-Wl,-rpath,$SYMRUSTC_RUNTIME_DIR \
  "$@" \
|| rustc_exit_code=$?

rm -f "$target_d/belcarra"
ln -s "$target_d_d/belcarra-$metadata" "$target_d/belcarra"

if [[ ! -v SYMRUSTC_SKIP_FAIL ]] ; then
    exit $rustc_exit_code
else
    echo "$target: rustc exit code: $rustc_exit_code" >&2
fi
