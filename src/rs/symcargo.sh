#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

RUSTC=symrustc \
exec $SYMRUSTC_CARGO \
  "$@"