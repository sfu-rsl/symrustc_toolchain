#!/bin/bash

set -euxo pipefail

# Set up Ubuntu environment
docker_b base

# Set up project source
docker_b source

# Build SymRustC core
docker_b symrustc

# Set up SymRustC distribution
docker_b symrustc_dist