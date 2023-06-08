#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

exec $SYMRUSTC_RUSTC \
  --sysroot="$SYMRUSTC_SYMSTD" \
  -Cpasses="symcc-module symcc-function" \
  -lSymRuntime \
  -L"$SYMRUSTC_RUNTIME_DIR" \
  -Clink-arg=-Wl,-rpath,"$SYMRUSTC_RUNTIME_DIR" \
  "$@"