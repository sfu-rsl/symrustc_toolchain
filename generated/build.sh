#!/bin/bash

set -euxo pipefail

# Build SymRustC core
docker_b symrustc

# Set up SymRustC distribution
docker_b symrustc_dist