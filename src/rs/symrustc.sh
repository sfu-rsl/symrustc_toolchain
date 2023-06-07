#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euo pipefail

exec $SYMRUSTC_RUSTC \
  -L"$SYMRUSTC_RUNTIME_DIR" \
  -Clink-arg=-Wl,-rpath,$SYMRUSTC_RUNTIME_DIR \
  "$@"