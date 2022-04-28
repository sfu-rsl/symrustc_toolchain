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

#
# Set up Ubuntu environment
#
FROM ubuntu:22.04 AS builder_base

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

ENV SYMRUSTC_LLVM_VERSION=11
ENV SYMRUSTC_LLVM_VERSION_LONG=11.1

RUN sudo apt-get update \
    && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
        clang-$SYMRUSTC_LLVM_VERSION \
        cmake \
        g++ \
        git \
        libz3-dev \
        ninja-build \
        python3-pip \
    && sudo apt-get clean

ENV SYMRUSTC_HOME=$HOME/belcarra_source
ENV SYMRUSTC_HOME_CPP=$SYMRUSTC_HOME/src/cpp
ENV SYMRUSTC_HOME_RS=$SYMRUSTC_HOME/src/rs
ENV SYMCC_LIBCXX_PATH=$HOME/libcxx_symcc_install

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
    git -C "$dir" submodule update --init --recursive

#
RUN ln -s ~/rust_source/src/llvm-project llvm_source
RUN ln -s ~/llvm_source/symcc symcc_source

# Note: Depending on the commit revision, the Rust compiler source may not have yet a SymCC directory. In this docker stage, we treat such case as a "non-aborting failure" (subsequent stages may raise different errors).
RUN if [ -d symcc_source ] ; then \
      cd symcc_source \
      && current=$(git log -1 --pretty=format:%H) \
# Note: Ideally, all submodules must also follow the change of version happening in the super-root project.
      && git checkout origin/main/$(git branch -r --contains "$current" | tr '/' '\n' | tail -n 1) \
      && cp -a . ~/symcc_source_main \
      && git checkout "$current"; \
    fi

# Download AFL
RUN git clone --depth 1 -b v2.56b https://github.com/google/AFL.git afl


#
# Set up project dependencies
#
FROM builder_source AS builder_depend

RUN sudo apt-get update \
    && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
        llvm-$SYMRUSTC_LLVM_VERSION-dev \
        llvm-$SYMRUSTC_LLVM_VERSION-tools \
        python2 \
        zlib1g-dev \
    && sudo apt-get clean
RUN pip3 install lit
ENV PATH=$HOME/.local/bin:$PATH


#
# Build AFL
#
FROM builder_source AS builder_afl

RUN cd afl \
    && make


#
# Build SymCC simple backend
#
FROM builder_depend AS builder_symcc_simple
RUN mkdir symcc_build_simple \
    && cd symcc_build_simple \
    && cmake -G Ninja ~/symcc_source_main \
        -DLLVM_VERSION_FORCE=$SYMRUSTC_LLVM_VERSION_LONG \
        -DQSYM_BACKEND=OFF \
        -DCMAKE_BUILD_TYPE=RelWithDebInfo \
        -DZ3_TRUST_SYSTEM_VERSION=on \
    && ninja check


#
# Build LLVM libcxx using SymCC simple backend
#
FROM builder_symcc_simple AS builder_symcc_libcxx
RUN export SYMCC_REGULAR_LIBCXX=yes SYMCC_NO_SYMBOLIC_INPUT=yes \
  && mkdir -p rust_source/build/x86_64-unknown-linux-gnu/llvm/build \
  && cd rust_source/build/x86_64-unknown-linux-gnu/llvm/build \
  && cmake -G Ninja ~/llvm_source/llvm \
  -DLLVM_ENABLE_PROJECTS="libcxx;libcxxabi" \
  -DLLVM_TARGETS_TO_BUILD="X86" \
  -DLLVM_DISTRIBUTION_COMPONENTS="cxx;cxxabi;cxx-headers" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=$SYMCC_LIBCXX_PATH \
  -DCMAKE_C_COMPILER=$HOME/symcc_build_simple/symcc \
  -DCMAKE_CXX_COMPILER=$HOME/symcc_build_simple/sym++ \
  && ninja distribution \
  && ninja install-distribution


#
# Build SymCC Qsym backend
#
FROM builder_symcc_libcxx AS builder_symcc_qsym
RUN mkdir symcc_build \
    && cd symcc_build \
    && cmake -G Ninja ~/symcc_source_main \
        -DLLVM_VERSION_FORCE=$SYMRUSTC_LLVM_VERSION_LONG \
        -DQSYM_BACKEND=ON \
        -DCMAKE_BUILD_TYPE=RelWithDebInfo \
        -DZ3_TRUST_SYSTEM_VERSION=on \
    && ninja check


#
# Build SymLLVM
#
FROM builder_source AS builder_symllvm

COPY --chown=ubuntu:ubuntu src/llvm/cmake.sh $SYMRUSTC_HOME/src/llvm/

RUN mkdir -p rust_source/build/x86_64-unknown-linux-gnu/llvm/build \
  && cd -P rust_source/build/x86_64-unknown-linux-gnu/llvm/build \
  && $SYMRUSTC_HOME/src/llvm/cmake.sh


#
# Build SymRustC core
#
FROM builder_source AS builder_symrustc

RUN sudo apt-get update \
    && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
        curl \
    && sudo apt-get clean

#

COPY --chown=ubuntu:ubuntu --from=builder_symcc_qsym $HOME/symcc_build symcc_build

RUN mkdir -p rust_source/build/x86_64-unknown-linux-gnu
COPY --chown=ubuntu:ubuntu --from=builder_symllvm $HOME/rust_source/build/x86_64-unknown-linux-gnu/llvm rust_source/build/x86_64-unknown-linux-gnu/llvm

#

RUN export SYMCC_NO_SYMBOLIC_INPUT=yes \
    && cd rust_source \
    && sed -e 's/#ninja = false/ninja = true/' \
        config.toml.example > config.toml \
    && sed -i -e 's/is_x86_feature_detected!("sse2")/false \&\& &/' \
        src/librustc_span/analyze_source_file.rs \
    && export SYMCC_RUNTIME_DIR=~/symcc_build/SymRuntime-prefix/src/SymRuntime-build \
    && /usr/bin/python3 ./x.py build --stage 2

#

ARG SYMRUSTC_RUST_BUILD=$HOME/rust_source/build/x86_64-unknown-linux-gnu
ARG SYMRUSTC_RUST_BUILD_STAGE=$SYMRUSTC_RUST_BUILD/stage2

ENV SYMRUSTC_CARGO=$SYMRUSTC_RUST_BUILD/stage0/bin/cargo
ENV SYMRUSTC_RUSTC=$SYMRUSTC_RUST_BUILD_STAGE/bin/rustc
ENV SYMRUSTC_LD_LIBRARY_PATH=$SYMRUSTC_RUST_BUILD_STAGE/lib
ENV PATH=$HOME/.cargo/bin:$PATH

COPY --chown=ubuntu:ubuntu --from=builder_symcc_libcxx $SYMCC_LIBCXX_PATH $SYMCC_LIBCXX_PATH

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
# Build concolic Rust examples
#
FROM builder_symrustc_main AS builder_examples_rs

ARG SYMRUSTC_CI

ARG SYMRUSTC_SKIP_FAIL

RUN cd belcarra_source/examples \
    && $SYMRUSTC_HOME_RS/fold_symrustc_build.sh

RUN cd belcarra_source/examples \
    && $SYMRUSTC_HOME_RS/fold_symrustc_run.sh


#
# Build additional tools
#
FROM builder_symrustc AS builder_addons

ARG SYMRUSTC_CI

COPY --chown=ubuntu:ubuntu src/rs/env0.sh $SYMRUSTC_HOME_RS/
COPY --chown=ubuntu:ubuntu src/rs/env.sh $SYMRUSTC_HOME_RS/
COPY --chown=ubuntu:ubuntu src/rs/parse_args.sh $SYMRUSTC_HOME_RS/
COPY --chown=ubuntu:ubuntu src/rs/wait_all.sh $SYMRUSTC_HOME_RS/

RUN cd ~/symcc_source/util/symcc_fuzzing_helper \
    && $SYMRUSTC_HOME_RS/env.sh $SYMRUSTC_CARGO install --path $PWD


#
# Build extended main
#
FROM builder_symrustc_main AS builder_extended_main

RUN sudo apt-get update \
    && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
        build-essential \
        libllvm$SYMRUSTC_LLVM_VERSION \
        zlib1g \
    && sudo apt-get clean

RUN ln -s ~/symcc_source/util/pure_concolic_execution.sh symcc_build
COPY --chown=ubuntu:ubuntu --from=builder_afl $HOME/afl afl
COPY --chown=ubuntu:ubuntu --from=builder_addons $HOME/.cargo .cargo

ENV PATH=$HOME/symcc_build:$PATH

ENV AFL_PATH=$HOME/afl
ENV AFL_CC=clang-$SYMRUSTC_LLVM_VERSION
ENV AFL_CXX=clang++-$SYMRUSTC_LLVM_VERSION


#
# Build concolic C++ examples - SymCC/Z3, libcxx regular
#
FROM builder_symcc_simple AS builder_examples_cpp_z3_libcxx_reg

COPY --chown=ubuntu:ubuntu src/cpp belcarra_source/src/cpp
COPY --chown=ubuntu:ubuntu examples belcarra_source/examples

RUN cd belcarra_source/examples \
    && export SYMCC_REGULAR_LIBCXX=yes \
    && $SYMRUSTC_HOME_CPP/main_fold_sym++_simple_z3.sh


#
# Build concolic C++ examples - SymCC/Z3, libcxx instrumented
#
FROM builder_symcc_libcxx AS builder_examples_cpp_z3_libcxx_inst

COPY --chown=ubuntu:ubuntu src/cpp belcarra_source/src/cpp
COPY --chown=ubuntu:ubuntu examples belcarra_source/examples

RUN cd belcarra_source/examples \
    && $SYMRUSTC_HOME_CPP/main_fold_sym++_simple_z3.sh


#
# Build concolic C++ examples - SymCC/QSYM
#
FROM builder_symcc_qsym AS builder_examples_cpp_qsym

RUN mkdir /tmp/output

COPY --chown=ubuntu:ubuntu src/cpp belcarra_source/src/cpp
COPY --chown=ubuntu:ubuntu examples belcarra_source/examples

RUN cd belcarra_source/examples \
    && $SYMRUSTC_HOME_CPP/main_fold_sym++_qsym.sh


#
# Build concolic C++ examples - Only clang
#
FROM builder_source AS builder_examples_cpp_clang

COPY --chown=ubuntu:ubuntu src/cpp belcarra_source/src/cpp
COPY --chown=ubuntu:ubuntu examples belcarra_source/examples

RUN cd belcarra_source/examples \
    && $SYMRUSTC_HOME_CPP/main_fold_clang++.sh
