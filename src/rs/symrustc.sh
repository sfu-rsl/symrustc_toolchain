#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

if [[ ! -v SYMRUSTC_RUSTC ]]; then
    echo "SYMRUSTC_RUSTC is not set"
    exit 1
fi

if [[ ! -v SYMRUSTC_SYMSTD ]]; then
    echo "SYMRUSTC_SYMSTD is not set"
    exit 1
fi

SYMCC_INPUT_FILE=$SYMRUSTC_INPUT_FILE \
SYMCC_NO_SYMBOLIC_INPUT=$SYMRUSTC_NO_SYMBOLIC_INPUT \
SYMCC_OUTPUT_DIR=$SYMRUSTC_OUTPUT_DIR \
exec $SYMRUSTC_RUSTC \
  --sysroot="$SYMRUSTC_SYMSTD" \
  -Cpasses="symcc-module symcc-function" \
  -lSymRuntime \
  -L"$SYMRUSTC_RUNTIME_DIR" \
  -Clink-arg=-Wl,-rpath,"$SYMRUSTC_RUNTIME_DIR" \
  "$@"