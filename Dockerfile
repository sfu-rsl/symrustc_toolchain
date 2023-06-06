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


#
# Set up project source
#
FROM builder_base AS builder_source

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
      git clone --depth 1 -b "$SYMRUSTC_BRANCH" https://github.com/sfu-rsl/symrustc.git belcarra_source0; \
      ln -s ~/belcarra_source0/src/rs/rust_source; \
    fi

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

COPY --chown=ubuntu:ubuntu --from=symcc_dist /home/dist_qsym symcc_build
COPY --chown=ubuntu:ubuntu --from=symcc_dist /home/z3_build z3_build
ENV LD_LIBRARY_PATH=$HOME/z3_build/dist/lib:$LD_LIBRARY_PATH

RUN mkdir -p rust_source/build/x86_64-unknown-linux-gnu
COPY --chown=ubuntu:ubuntu --from=llvm_dist /home/dist rust_source/build/x86_64-unknown-linux-gnu/llvm

#

ENV SYMRUSTC_RUNTIME_DIR=$HOME/symcc_build/SymRuntime-prefix/src/SymRuntime-build

RUN export SYMCC_NO_SYMBOLIC_INPUT=yes \
    && cd rust_source \
    && sed -i -e 's/is_x86_feature_detected!("sse2")/false \&\& &/' \
        compiler/rustc_span/src/analyze_source_file.rs \
    && export SYMCC_RUNTIME_DIR=$SYMRUSTC_RUNTIME_DIR \
    && /usr/bin/python3 ./x.py build --stage 2

#

ARG SYMRUSTC_RUST_BUILD=$HOME/rust_source/build/x86_64-unknown-linux-gnu
ARG SYMRUSTC_RUST_BUILD_STAGE=$SYMRUSTC_RUST_BUILD/stage2

ENV SYMRUSTC_CARGO=$SYMRUSTC_RUST_BUILD/stage0/bin/cargo
ENV SYMRUSTC_RUSTC=$SYMRUSTC_RUST_BUILD_STAGE/bin/rustc
ENV SYMRUSTC_LD_LIBRARY_PATH=$SYMRUSTC_RUST_BUILD_STAGE/lib
ENV SYMRUSTC_LIBAFL_EXAMPLE0=$HOME/belcarra_source/examples/source_0_original_1c8_rs
ENV PATH=$HOME/.cargo/bin:$PATH

COPY --chown=ubuntu:ubuntu --from=symcc_dist /home/dist_libcxx $SYMCC_LIBCXX_PATH

ENV SYMCC_PASS_DIR=$HOME/symcc_build

RUN mkdir clang_symcc_on \
    && ln -s ~/symcc_build/symcc clang_symcc_on/clang \
    && ln -s ~/symcc_build/sym++ clang_symcc_on/clang++

RUN mkdir clang_symcc_off \
    && ln -s $(which clang-$SYMRUSTC_LLVM_VERSION) clang_symcc_off/clang \
    && ln -s $(which clang++-$SYMRUSTC_LLVM_VERSION) clang_symcc_off/clang++


#
# Build SymRustC main
#
FROM builder_symrustc AS builder_symrustc_main

RUN sudo apt-get update \
    && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
        bsdmainutils \
    && sudo apt-get clean

COPY --chown=ubuntu:ubuntu src/rs belcarra_source/src/rs
COPY --chown=ubuntu:ubuntu examples belcarra_source/examples


#
# Set up Ubuntu/Rust environment
#
FROM builder_symrustc AS builder_base_rust

ENV RUSTUP_HOME=$HOME/rustup \
    CARGO_HOME=$HOME/cargo \
    PATH=$HOME/cargo/bin:$PATH \
    RUST_VERSION=1.65.0

# https://github.com/rust-lang/docker-rust/blob/76e3311a6326bc93a1e96ad7ae06c05763b62b18/1.65.0/bullseye/Dockerfile
RUN set -eux; \
    dpkgArch="$(dpkg --print-architecture)"; \
    case "${dpkgArch##*-}" in \
        amd64) rustArch='x86_64-unknown-linux-gnu'; rustupSha256='5cc9ffd1026e82e7fb2eec2121ad71f4b0f044e88bca39207b3f6b769aaa799c' ;; \
        armhf) rustArch='armv7-unknown-linux-gnueabihf'; rustupSha256='48c5ecfd1409da93164af20cf4ac2c6f00688b15eb6ba65047f654060c844d85' ;; \
        arm64) rustArch='aarch64-unknown-linux-gnu'; rustupSha256='e189948e396d47254103a49c987e7fb0e5dd8e34b200aa4481ecc4b8e41fb929' ;; \
        i386) rustArch='i686-unknown-linux-gnu'; rustupSha256='0e0be29c560ad958ba52fcf06b3ea04435cb3cd674fbe11ce7d954093b9504fd' ;; \
        *) echo >&2 "unsupported architecture: ${dpkgArch}"; exit 1 ;; \
    esac; \
    url="https://static.rust-lang.org/rustup/archive/1.25.1/${rustArch}/rustup-init"; \
    curl -O "$url"; \
    echo "${rustupSha256} *rustup-init" | sha256sum -c -; \
    chmod +x rustup-init; \
    ./rustup-init -y --no-modify-path --profile minimal --default-toolchain $RUST_VERSION --default-host ${rustArch}

RUN rustup component add rustfmt


#
# Build LibAFL solving runtime
#
FROM builder_base_rust AS builder_libafl_solving

ARG SYMRUSTC_CI

RUN if [[ -v SYMRUSTC_CI ]] ; then \
      echo "Ignoring the execution" >&2; \
    else \
      cargo install cargo-make; \
    fi

COPY --chown=ubuntu:ubuntu src/rs belcarra_source/src/rs
COPY --chown=ubuntu:ubuntu examples belcarra_source/examples
ARG SYMRUSTC_LIBAFL_EXAMPLE=$SYMRUSTC_LIBAFL_EXAMPLE0

# Updating the harness
RUN if [[ -v SYMRUSTC_CI ]] ; then \
      echo "Ignoring the execution" >&2; \
    else \
      cd $SYMRUSTC_LIBAFL_SOLVING_DIR/fuzzer \
      && rm -rf harness \
      && cp -R $SYMRUSTC_LIBAFL_EXAMPLE harness; \
    fi

# Building the client-server main fuzzing loop completely sanitized
RUN if [[ -v SYMRUSTC_CI ]] ; then \
      mkdir $SYMRUSTC_LIBAFL_SOLVING_DIR/target; \
      echo "Ignoring the execution" >&2; \
    else \
      cd $SYMRUSTC_LIBAFL_SOLVING_DIR \
      && $SYMRUSTC_HOME_RS/libafl_cargo.sh; \
    fi


#
# Build LibAFL solving runtime main
#
FROM builder_symrustc_main AS builder_libafl_solving_main

RUN sudo apt-get update \
    && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
# Installing "nc" to later check if a given port is opened or closed
        netcat-openbsd \
        psmisc \
    && sudo apt-get clean

COPY --chown=ubuntu:ubuntu --from=builder_libafl_solving $SYMRUSTC_LIBAFL_SOLVING_DIR/target $SYMRUSTC_LIBAFL_SOLVING_DIR/target

# Pointing to the Rust runtime back-end
RUN cd -P $SYMRUSTC_RUNTIME_DIR/.. \
    && ln -s $SYMRUSTC_LIBAFL_SOLVING_DIR/target/release "$(basename $SYMRUSTC_RUNTIME_DIR)0"


#
# Build concolic Rust examples for LibAFL solving
#
FROM builder_libafl_solving_main AS builder_libafl_solving_example

ARG SYMRUSTC_CI
ARG SYMRUSTC_LIBAFL_EXAMPLE=$SYMRUSTC_LIBAFL_EXAMPLE0
ARG SYMRUSTC_LIBAFL_EXAMPLE_SKIP_BUILD_SOLVING
#ARG SYMRUSTC_LIBAFL_SOLVING_OBJECTIVE=yes

RUN if [[ -v SYMRUSTC_CI ]] ; then \
      echo "Ignoring the execution" >&2; \
    else \
      cd $SYMRUSTC_LIBAFL_EXAMPLE \
      && $SYMRUSTC_HOME_RS/libafl_solving_build.sh; \
    fi

RUN if [[ -v SYMRUSTC_CI ]] ; then \
      echo "Ignoring the execution" >&2; \
    else \
      cd $SYMRUSTC_LIBAFL_EXAMPLE \
      && $SYMRUSTC_HOME_RS/libafl_solving_run.sh test; \
    fi
