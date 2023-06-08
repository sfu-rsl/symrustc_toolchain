#!/bin/bash

set -euxo pipefail

# Build SymRustC core
docker_b builder

# Set up SymRustC distribution
docker_b dist