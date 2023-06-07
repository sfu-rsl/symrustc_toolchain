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
FROM ubuntu:22.10 AS builder_base

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

FROM builder_base AS builder_reqs
ENV SYMRUSTC_LLVM_VERSION=15

RUN sudo apt-get update \
    && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
        clang-tools-$SYMRUSTC_LLVM_VERSION \
        mlir-$SYMRUSTC_LLVM_VERSION-tools \
        libmlir-$SYMRUSTC_LLVM_VERSION-dev \
        cmake \
        g++ \
        git \
        ninja-build \
        python3-pip \
    && sudo apt-get clean

#
# Set up project source
#
FROM builder_reqs AS builder_source

ENV SYMRUSTC_HOME=$HOME/belcarra_source
ENV SYMRUSTC_HOME_CPP=$SYMRUSTC_HOME/src/cpp
ENV SYMRUSTC_HOME_RS=$SYMRUSTC_HOME/src/rs
ENV SYMCC_LIBCXX_PATH=$HOME/libcxx_symcc_install
ENV SYMRUSTC_LIBAFL_SOLVING_DIR=$HOME/libafl/fuzzers/libfuzzer_rust_concolic
ENV SYMRUSTC_LIBAFL_TRACING_DIR=$HOME/libafl/libafl_concolic/test

# Setup Rust compiler source
ARG SYMRUSTC_RUST_VERSION
ARG SYMRUSTC_BRANCH
RUN if [[ -v SYMRUSTC_RUST_VERSION ]] ; then \
      git clone --depth 1 -b $SYMRUSTC_RUST_VERSION https://github.com/sfu-rsl/rust.git rust_source; \
    else \
      set -e; \
      git clone --depth 1 -b "$SYMRUSTC_BRANCH" https://github.com/sfu-rsl/symrustc_toolchain2.git belcarra_source0; \
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

FROM ghcr.io/sfu-rsl/llvm_dist:$DISTS_TAG AS llvm_dist
FROM ghcr.io/sfu-rsl/symcc_dist:$DISTS_TAG AS symcc_dist

#
# Build SymRustC core
#
FROM builder_source AS builder_symrustc

RUN sudo apt-get update \
    && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
        curl \
    && sudo apt-get clean

#

COPY --chown=ubuntu:ubuntu --from=symcc_dist /home/dist_noop symcc_noop
COPY --chown=ubuntu:ubuntu --from=symcc_dist /home/z3_build z3_build
ENV LD_LIBRARY_PATH=$HOME/z3_build/dist/lib:$LD_LIBRARY_PATH

ENV SYMRUSTC_LLVM_DIST_PATH=$HOME/llvm_dist
COPY --chown=ubuntu:ubuntu --from=llvm_dist /home/dist $SYMRUSTC_LLVM_DIST_PATH

COPY --chown=ubuntu:ubuntu src/rs/rustc.rs $HOME/rust_source/src/bootstrap/bin
RUN sudo ln -s $HOME/symcc_noop/SymRuntime-prefix/src/SymRuntime-build/libSymRuntime.so /usr/lib/libSymRuntime.so

#

RUN export SYMCC_NO_SYMBOLIC_INPUT=yes \
    && cd rust_source \
    && ./configure --llvm-config=$SYMRUSTC_LLVM_DIST_PATH/bin/llvm-config \
    && sed -i -e 's/is_x86_feature_detected!("sse2")/false \&\& &/' \
        compiler/rustc_span/src/analyze_source_file.rs \
    && /usr/bin/python3 ./x.py build --stage 2

#

FROM builder_reqs AS builder_symrustc_dist
COPY --chown=ubuntu:ubuntu --from=symcc_dist /home/dist_qsym symcc_qsym
COPY --chown=ubuntu:ubuntu --from=symcc_dist /home/dist_libcxx $SYMCC_LIBCXX_PATH
COPY --chown=ubuntu:ubuntu --from=symcc_dist /home/z3_build z3_build
ENV LD_LIBRARY_PATH=$HOME/z3_build/dist/lib:$LD_LIBRARY_PATH

ENV SYMRUSTC_LLVM_DIST_PATH=$HOME/llvm_dist
COPY --chown=ubuntu:ubuntu --from=llvm_dist /home/dist $SYMRUSTC_LLVM_DIST_PATH

ARG SYMRUSTC_RUST_BUILD=$HOME/rust_source/build/x86_64-unknown-linux-gnu
ARG SYMRUSTC_RUST_BUILD_STAGE=$SYMRUSTC_RUST_BUILD/stage2
ARG SYMRUSTC_DIST=$HOME/symrustc_dist

# ENV SYMRUSTC_CARGO=$SYMRUSTC_RUST_BUILD/stage0/bin/cargo
ENV SYMRUSTC_RUSTC=$SYMRUSTC_DIST/bin/rustc
ENV SYMRUSTC_LD_LIBRARY_PATH=$SYMRUSTC_DIST/lib
ENV PATH=$HOME/.cargo/bin:$PATH

ENV SYMCC_PASS_DIR=$HOME/symcc_build
ENV SYMRUSTC_RUNTIME_DIR=$SYMCC_PASS_DIR/SymRuntime-prefix/src/SymRuntime-build
RUN ln -s ~/symcc_qsym $SYMCC_PASS_DIR

COPY --chown=ubuntu:ubuntu --from=builder_symrustc /home/ubuntu/rust_source/build/x86_64-unknown-linux-gnu/stage2 $SYMRUSTC_DIST
COPY --chown=ubuntu:ubuntu --from=builder_symrustc /home/ubuntu/symcc_noop/SymRuntime-prefix/src/SymRuntime-build/libSymRuntime.so $SYMRUSTC_LD_LIBRARY_PATH/libSymRuntime.so

ENV SYMRUSTC_HOME=$HOME/belcarra_source
ENV SYMRUSTC_HOME_CPP=$SYMRUSTC_HOME/src/cpp
ENV SYMRUSTC_HOME_RS=$SYMRUSTC_HOME/src/rs
COPY --chown=ubuntu:ubuntu src/rs $SYMRUSTC_HOME_RS
COPY --chown=ubuntu:ubuntu examples $SYMRUSTC_HOME/examples