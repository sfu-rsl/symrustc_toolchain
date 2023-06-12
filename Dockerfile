# SPDX-License-Identifier
# Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

# #

# This file is part of SymCC.
#
# SymCC is free software: you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later
# version.
#
# SymCC is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# SymCC. If not, see <https://www.gnu.org/licenses/>.

# #

ARG DISTS_TAG

#
# Set up Ubuntu environment
#
FROM ubuntu:22.10 AS base

SHELL ["/bin/bash", "-c"]

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        sudo \
    && apt-get clean

RUN useradd -m -s /bin/bash ubuntu \
    && echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/ubuntu

USER ubuntu
ENV HOME=/home/ubuntu
WORKDIR $HOME

##################################################

FROM ghcr.io/sfu-rsl/llvm_dist:$DISTS_TAG AS llvm_dist
FROM ghcr.io/sfu-rsl/symcc_dist:$DISTS_TAG AS symcc_dist

##################################################

FROM base AS commons

RUN sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
        git \
        g++ \
        curl \
    && sudo apt-get clean

COPY --chown=ubuntu:ubuntu --from=symcc_dist /home/z3_build/dist/lib /usr/local/lib
ENV LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH

##################################################

#
# Set up project source
#
FROM commons AS source

# Setup Rust compiler source
ARG SYMRUSTC_RUST_VERSION
ARG SYMRUSTC_BRANCH
RUN if [[ -v SYMRUSTC_RUST_VERSION ]] ; then \
      git clone --depth 1 -b $SYMRUSTC_RUST_VERSION https://github.com/sfu-rsl/rust.git rust_source; \
    else \
      set -e; \
      git clone --depth 1 -b "$SYMRUSTC_BRANCH" https://github.com/sfu-rsl/symrustc_toolchain.git belcarra_source0; \
      ln -s ~/belcarra_source0/src/rs/rust_source; \
    fi

RUN pwd && ls -la

# Init submodules
RUN [[ -v SYMRUSTC_RUST_VERSION ]] && dir='rust_source' || dir='belcarra_source0' ; \
    pushd "$dir" \
    # Let's exclude llvm-project from clone as we will use the distribution image.
    && git -c submodule."src/rs/rust_source".update=none submodule update --init --recursive \
    && git submodule update --init "src/rs/rust_source" \
    && git -C ./src/rs/rust_source -c submodule."src/llvm-project".update=none submodule update --init --recursive \
    && popd

##################################################

#
# Build SymRustC core
#
FROM source AS builder

ARG SYMRUSTC_LLVM_VERSION=15

RUN sudo apt-get update \
    && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
        clang-tools-$SYMRUSTC_LLVM_VERSION \
        mlir-$SYMRUSTC_LLVM_VERSION-tools \
        libmlir-$SYMRUSTC_LLVM_VERSION-dev \
        cmake \
        ninja-build \
        python3-pip \
    && sudo apt-get clean


COPY --chown=ubuntu:ubuntu --from=symcc_dist /home/dist_noop symcc_noop
RUN sudo ln -s $HOME/symcc_noop/SymRuntime-prefix/src/SymRuntime-build/libSymRuntime.so /usr/lib/libSymRuntime.so

WORKDIR $HOME/rust_source

ARG SYMRUSTC_LLVM_DIST_PATH=$HOME/llvm_dist
COPY --chown=ubuntu:ubuntu --from=llvm_dist /home/dist $SYMRUSTC_LLVM_DIST_PATH
RUN ./configure \
    --llvm-config=$SYMRUSTC_LLVM_DIST_PATH/bin/llvm-config \
    --dist-compression-formats=gz

ARG BUILD_ARTIFACTS_PATH=$HOME/symrustc_build
RUN mkdir -p $BUILD_ARTIFACTS_PATH

# Building an instrumented version of the standard library.
COPY --chown=ubuntu:ubuntu src/rs/rustc.rs src/bootstrap/bin/rustc.rs
RUN export SYMCC_NO_SYMBOLIC_INPUT=yes \
    && sed -i -e 's/is_x86_feature_detected!("sse2")/false \&\& &/' \
        compiler/rustc_span/src/analyze_source_file.rs \
    && ./x.py dist rust-std
RUN cp -r build/dist $BUILD_ARTIFACTS_PATH

# This is the normal compiler that will be distributed with our customized LLVM 
# distribution (that contains the SymCC pass.) 
# Normally, a shared library named libLLVM* is included in the toolchain.
# It looks like it is possible to achieve that using the `llvm-has-rust-patches`
# config.
COPY --chown=ubuntu:ubuntu src/rs/rustc_original.rs src/bootstrap/bin/rustc.rs
RUN sed -i -e 's/is_x86_feature_detected!("sse2")/false \&\& &/' \
        compiler/rustc_span/src/analyze_source_file.rs \
    # It looks like the build system does not notice the change in rustc.rs,
    # so doesn't rebuild the library.
    && ./x.py clean \
    && ./x.py build --stage 2
RUN cp -r build/x86_64-unknown-linux-gnu/stage2 $BUILD_ARTIFACTS_PATH/stage2_normal
RUN mkdir -p $BUILD_ARTIFACTS_PATH/stage0 && cp -r build/x86_64-unknown-linux-gnu/stage0/bin $BUILD_ARTIFACTS_PATH/stage0/bin

##################################################

FROM commons AS dist

COPY --chown=ubuntu:ubuntu --from=symcc_dist /home/dist_qsym symcc_qsym

ARG SYMRUSTC_DIST=$HOME/symrustc_dist
ARG SYMRUSTC_DIST_NORMAL=$SYMRUSTC_DIST/normal
ARG SYMRUSTC_DIST_SYMSTD=$SYMRUSTC_DIST/symstd

ARG BUILD_ARTIFACTS_PATH=$HOME/symrustc_build

COPY --chown=ubuntu:ubuntu --from=builder $BUILD_ARTIFACTS_PATH/stage2_normal $SYMRUSTC_DIST_NORMAL
COPY --chown=ubuntu:ubuntu --from=builder $BUILD_ARTIFACTS_PATH/stage0/bin/cargo $SYMRUSTC_DIST_NORMAL/bin/cargo

COPY --chown=ubuntu:ubuntu --from=builder $BUILD_ARTIFACTS_PATH/dist/rust-std-*-dev-x86_64-unknown-linux-gnu.tar.gz /tmp/rust-symstd-dev-x86_64-unknown-linux-gnu.tar.gz
RUN mkdir -p $SYMRUSTC_DIST_SYMSTD && \
    tar -xf /tmp/rust-symstd-dev-x86_64-unknown-linux-gnu.tar.gz \
        --directory=$SYMRUSTC_DIST_SYMSTD \
        --wildcards rust-std-*-dev-x86_64-unknown-linux-gnu/rust-std-x86_64-unknown-linux-gnu --strip-components=2 && \
    rm /tmp/rust-symstd-dev-x86_64-unknown-linux-gnu.tar.gz

ENV SYMRUSTC_CARGO=$SYMRUSTC_DIST_NORMAL/bin/cargo
ENV SYMRUSTC_RUSTC=$SYMRUSTC_DIST_NORMAL/bin/rustc
ENV SYMRUSTC_SYMSTD=$SYMRUSTC_DIST_SYMSTD

COPY --chown=ubuntu:ubuntu src/rs/symrustc.sh $SYMRUSTC_DIST_SYMSTD/bin/rustc
COPY --chown=ubuntu:ubuntu src/rs/symcargo.sh $SYMRUSTC_DIST_SYMSTD/bin/cargo

RUN curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain none --profile minimal \
    && source "$HOME/.cargo/env" \
    && rustup toolchain link symrustc $SYMRUSTC_DIST_SYMSTD \
    && rustup toolchain link normal $SYMRUSTC_DIST_NORMAL \
    && rustup default normal \
    ;

RUN ln -s $SYMRUSTC_SYMSTD/bin/rustc $HOME/.cargo/bin/symrustc
RUN ln -s $SYMRUSTC_SYMSTD/bin/cargo $HOME/.cargo/bin/symcargo

ARG SYMCC_BUILD_DIR=$HOME/symcc_qsym
ENV SYMRUSTC_RUNTIME_DIR=$SYMCC_BUILD_DIR/SymRuntime-prefix/src/SymRuntime-build
ENV SYMCC_OUTPUT_DIR=/tmp/output

RUN mkdir -p $SYMCC_OUTPUT_DIR

COPY --chown=ubuntu:ubuntu examples $HOME/examples