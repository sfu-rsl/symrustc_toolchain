#!/bin/bash

# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

set -euxo pipefail

RUST_SOURCE=builder_rustc_source

docker_b --target builder_source -t $RUST_SOURCE --build-arg SYMRUSTC_RUST_VERSION="$(echo "$SYMRUSTC_BRANCH" | rev | cut -d '/' -f 1 | rev)" .
docker_b -f rustc.Dockerfile --build-arg RUST_SOURCE=$RUST_SOURCE .
