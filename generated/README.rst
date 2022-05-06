.. SPDX-License-Identifier

.. Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

SymRustC
********

SymRustC is a tool implemented in the Belcarra project
(\ `https://github.com/sfu-rsl <https://github.com/sfu-rsl>`_\ ) for practical and
efficient symbolic execution of Rust programs.

Like a compiler, the implementation of SymRustC is made of several
sub-components, that may come from different repositories. From a Rust
source in input, we basically obtain a concolic binary in output by
calling SymCC (its compiler part) at the LLVM level of the Rust
compilation process. In the end, the concolic binary enjoys the
property of being immediately compatible with the C++ runtime part of
SymCC (also designated as the QSYM or Z3 part), and can be used as
such, i.e. with the usual options and environment setting that we
usually put in place before running a SymCC concolic binary compiled
from C or C++.

The most notable components of SymRustC are listed below, they were in
particular combined and integrated together as Git submodules (from
top to bottom in nesting sub-encapsulation-module order):

- Rust compiler

  - \ `https://github.com/sfu-rsl/rust <https://github.com/sfu-rsl/rust>`_

    - \ `https://github.com/rust-lang/rust <https://github.com/rust-lang/rust>`_

- LLVM

  - \ `https://github.com/sfu-rsl/llvm-project <https://github.com/sfu-rsl/llvm-project>`_

    - \ `https://github.com/rust-lang/llvm-project <https://github.com/rust-lang/llvm-project>`_

      - \ `https://github.com/llvm/llvm-project <https://github.com/llvm/llvm-project>`_

- SymCC

  - \ `https://github.com/sfu-rsl/symcc <https://github.com/sfu-rsl/symcc>`_

    - \ `https://github.com/eurecom-s3/symcc <https://github.com/eurecom-s3/symcc>`_

- QSYM

  - \ `https://github.com/eurecom-s3/qsym <https://github.com/eurecom-s3/qsym>`_

    - \ `https://github.com/sslab-gatech/qsym <https://github.com/sslab-gatech/qsym>`_

- Z3

  - \ `https://github.com/Z3Prover/z3 <https://github.com/Z3Prover/z3>`_

Note that, at the time of writing, no modifications were made on the
last two components, QSYM and Z3.

Installing SymRustC
*******************

SymRustC should be easily installable/usable on most platforms and
operating systems supported by the Rust compiler and SymCC.

The rest of the document gives more details about the installation
procedure. Although our description aims to be generic and cover most
installation corner cases, we will take Ubuntu as an illustration
example. (Note that this choice is arbitrary and may change in the
future, with for instance more emphases on OS differences and setting
to be provided.)

Our installation instructions are described in Dockerfile format
(\ `https://docs.docker.com/engine/reference/builder/ <https://docs.docker.com/engine/reference/builder/>`_\ ),
which should be syntactically pretty close to most “standard”-shell
syntax.

Semantically though, whereas the use of Docker is not mandatory, for a
reader not familiar with the Dockerfile-language, we quickly list all
commands that will be subsequently used:

- \ ``ENV``\  exports the given variable in
  global shell-scope, so that subsequent shell-commands can use the exported
  variable, e.g. in their internal forked sub-shells.

- \ ``ARG``\  can be thought of as being
  similar to \ ``ENV``\ , except that its scope is
  more local. Without loss of generality, it can be understood as being
  restricted to the current paragraph/subsection of discourse.

- \ ``RUN``\  basically executes the given
  shell-command, with the possibility to use any variables prior
  exported by \ ``ENV``\  or
  \ ``ARG``\ .

- \ ``COPY``\  can be thought of as an
  instantiated version of \ ``RUN``\  to copy files
  across our fictive filesystem, except that it has the “meta”-ability
  to refer to specific paragraph/subsections that we are describing in
  the document, using in particular the
  \ ``--from=$FROM``\  option.

Note that the next presented installation-subsections are
topologically ordered, and thus have to be executed in specific order.
Whereas the specific topological-dependencies are normally mentioned
in the title, this information should not be taken as exclusive:
e.g. the \ ``--from=$FROM``\  option of
\ ``COPY``\  may create new explicit dependencies.

Source preparation
==================

builder_base: Set up Ubuntu environment (using ubuntu:22.04)
------------------------------------------------------------

Starting from a fresh Ubuntu machine, the installation will be made in
the \ ``$HOME``\  directory, and does not require
specific root permission.

However, we will suppose that the package
\ ``sudo``\  is installed, which will be
exclusively used by \ ``apt-get``\  in the next
incoming parts.

In addition to the above-mentioned docker command semantics, note
that:

- all \ ``RUN``\  used in the document will
  rely on Bash as shell
  (\ `https://www.gnu.org/software/bash/ <https://www.gnu.org/software/bash/>`_\ ).

- all \ ``COPY``\  used in the document will
  most of the time take the option
  \ ``--chown=$CHOWN``\ , and can be ignored by the
  reader. It is just a reminder signalling us that one does not need any
  specific root permission to do the copy.

builder_source: Set up project source (using builder_base)
----------------------------------------------------------

Certain OS may already come with some LLVM version(s) already
installed.  On the other hand, because the one we are working with is
a “predetermined” version, we have to explicitly tell the OS to try
install it (again). Besides, to be sure that our surrounding packages
will use that predetermined version, it is straightforward to
implement an option for the respective packages to force loading our
intended version, e.g. for the case of SymCC in CMakeLists syntax
(\ `https://cmake.org/cmake/help/latest/manual/cmake-commands.7.html <https://cmake.org/cmake/help/latest/manual/cmake-commands.7.html>`_\ ):

- \ `https://github.com/sfu-rsl/symcc/blob/8d3442870e6d56acd2f6bca77028d93abe8df854/CMakeLists.txt#L65 <https://github.com/sfu-rsl/symcc/blob/8d3442870e6d56acd2f6bca77028d93abe8df854/CMakeLists.txt#L65>`_

.. code:: Dockerfile
  
  ENV SYMRUSTC_LLVM_VERSION=11

Unfortunately, the above version that we give to the OS package
manager apt-get is slightly different from the one we give in
CMakeLists for cmake. This is because apt-get and cmake are
implementing their own heuristic-search while looking for the initial
versions requested by the user.

One solution is to make multiple declarations for the versions of
interest (and make sure that the correct variable is provided to the
respective apt-get or cmake software):

.. code:: Dockerfile
  
  ENV SYMRUSTC_LLVM_VERSION_LONG=11.1

Note that if we assign “11” for the version in CMakeLists, this will
ultimately be understood by default as “11.0”. Unfortunately,
“11.0” and “11.1” is considered as API-compatible in LLVM:

- \ `https://github.com/sfu-rsl/llvm-project/blob/a2f58d410b3bdfe71a3f6121fdcd281119e0e24e/llvm/cmake/modules/LLVMConfigVersion.cmake.in#L3 <https://github.com/sfu-rsl/llvm-project/blob/a2f58d410b3bdfe71a3f6121fdcd281119e0e24e/llvm/cmake/modules/LLVMConfigVersion.cmake.in#L3>`_

The following packages to install were originally coming from the
requirements of SymCC:

.. code:: Dockerfile
  
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

.. code:: Dockerfile
  
  ENV SYMRUSTC_HOME=$HOME/belcarra_source
  ENV SYMRUSTC_HOME_CPP=$SYMRUSTC_HOME/src/cpp
  ENV SYMRUSTC_HOME_RS=$SYMRUSTC_HOME/src/rs

Even if SymCC is not yet installed, we can enable the following
variable so that it is early available in global scope for future
importing images:

.. code:: Dockerfile
  
  ENV SYMCC_LIBCXX_PATH=$HOME/libcxx_symcc_install

The installation of SymRustC is currently performed through an
external git cloning, one other alternative would be a direct git
submodule integration of the cloned repository. It is notably at this
point where we explicitly specify the SymRustC version to use:

.. code:: Dockerfile
  
  # Download the Rust compiler with SymCC
  ARG SYMRUSTC_RUST_VERSION
  ENV SYMRUSTC_RUST_VERSION=${SYMRUSTC_RUST_VERSION:-symcc_comp_utils/1.47.0}
  RUN git clone -b $SYMRUSTC_RUST_VERSION --depth 1 https://github.com/sfu-rsl/rust.git rust_source
  
  # Init submodules
  RUN if git -C rust_source submodule status | grep "^-">/dev/null ; then \
        git -C rust_source submodule update --init --recursive; \
      fi
  
  #
  RUN ln -s ~/rust_source/src/llvm-project llvm_source
  RUN ln -s ~/llvm_source/symcc symcc_source

At the time of writing, the build of SymCC/Runtime is not yet
integrated to be made in the above SymCC submodule (i.e. not
automatically triggered while building SymRustC). We have to
separately build it inside another folder:

.. code:: Dockerfile
  
  # Note: Depending on the commit revision, the Rust compiler source may not have yet a SymCC directory. In this docker stage, we treat such case as a "non-aborting failure" (subsequent stages may raise different errors).
  RUN if [ -d symcc_source ] ; then \
        cd symcc_source \
        && current=$(git log -1 --pretty=format:%H) \
  # Note: Ideally, all submodules must also follow the change of version happening in the super-root project.
        && git checkout origin/main/$(git branch -r --contains "$current" | tr '/' '\n' | tail -n 1) \
        && cp -a . ~/symcc_source_main \
        && git checkout "$current"; \
      fi

The installation of AFL is optional for SymRustC, but one can already
download its source at this stage:

.. code:: Dockerfile
  
  # Download AFL
  RUN git clone -b v2.56b https://github.com/google/AFL.git afl

Building SymCC/Runtime
======================

The build of the runtime part of SymCC strongly resembles to how it is
done in its original repository:

- \ `https://github.com/eurecom-s3/symcc <https://github.com/eurecom-s3/symcc>`_

builder_depend: Set up project dependencies (using builder_source)
------------------------------------------------------------------

As prerequisite, the lit binary has to be installed.

.. code:: Dockerfile
  
  RUN sudo apt-get update \
      && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
          llvm-$SYMRUSTC_LLVM_VERSION-dev \
          llvm-$SYMRUSTC_LLVM_VERSION-tools \
          python2 \
          zlib1g-dev \
      && sudo apt-get clean
  RUN pip3 install lit
  ENV PATH=$HOME/.local/bin:$PATH

builder_afl: Build AFL (using builder_source)
---------------------------------------------

Since AFL is not used by the installation phase of SymRustC, this part
can be skipped.

.. code:: Dockerfile
  
  RUN cd afl \
      && make

builder_symcc_simple: Build SymCC simple backend (using builder_depend)
-----------------------------------------------------------------------

Note that we explicitly set the LLVM version to use.

.. code:: Dockerfile
  
  RUN mkdir symcc_build_simple \
      && cd symcc_build_simple \
      && cmake -G Ninja ~/symcc_source_main \
          -DLLVM_VERSION_FORCE=$SYMRUSTC_LLVM_VERSION_LONG \
          -DQSYM_BACKEND=OFF \
          -DCMAKE_BUILD_TYPE=RelWithDebInfo \
          -DZ3_TRUST_SYSTEM_VERSION=on \
      && ninja check

builder_symcc_libcxx: Build LLVM libcxx using SymCC simple backend (using builder_symcc_simple)
-----------------------------------------------------------------------------------------------

We build the necessary SymCC/LLVM component inside the same folder
location where the build of SymRustC/LLVM will be expected to happen.

Note that here SymCC is used as a “bootstrap” C compiler, whereas
while bootstrapping SymRustC, we will use the default native C
compiler (not SymCC). This may lead to numerous consequences whenever
one is trying to take advantage of incremental compilation of LLVM,
e.g. while trying to reuse the build here for building the LLVM part
of SymRustC.

.. code:: Dockerfile
  
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

builder_symcc_qsym: Build SymCC Qsym backend (using builder_symcc_libcxx)
-------------------------------------------------------------------------

Note that we explicitly set the LLVM version to use.

.. code:: Dockerfile
  
  RUN mkdir symcc_build \
      && cd symcc_build \
      && cmake -G Ninja ~/symcc_source_main \
          -DLLVM_VERSION_FORCE=$SYMRUSTC_LLVM_VERSION_LONG \
          -DQSYM_BACKEND=ON \
          -DCMAKE_BUILD_TYPE=RelWithDebInfo \
          -DZ3_TRUST_SYSTEM_VERSION=on \
      && ninja check

Building SymRustC
=================

builder_symllvm: Build SymLLVM (using builder_source)
-----------------------------------------------------

Before building SymRustC, we can build its LLVM component, called here
SymLLVM. It is actually not mandatory to separate the build of SymLLVM
from SymRustC, however, doing so may make the testing of respective
components easier. Also, since some significant part of the build time
is dedicated to the build of LLVM, this separation permits the
monitoring of each separated component compilation-time while
drawing up benchmark statistics.

.. code:: Dockerfile
  
  COPY --chown=ubuntu:ubuntu src/llvm/cmake.sh $SYMRUSTC_HOME/src/llvm/
  
  RUN mkdir -p rust_source/build/x86_64-unknown-linux-gnu/llvm/build \
    && cd rust_source/build/x86_64-unknown-linux-gnu/llvm/build \
    && $SYMRUSTC_HOME/src/llvm/cmake.sh

builder_symrustc: Build SymRustC (using builder_source)
-------------------------------------------------------

This part focuses on the main build of SymRustC.

.. code:: Dockerfile
  
  RUN sudo apt-get update \
      && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
          curl \
      && sudo apt-get clean
  
  #
  
  COPY --chown=ubuntu:ubuntu --from=builder_symcc_qsym $HOME/symcc_build symcc_build
  
  RUN mkdir -p rust_source/build/x86_64-unknown-linux-gnu
  COPY --chown=ubuntu:ubuntu --from=builder_symllvm $HOME/rust_source/build/x86_64-unknown-linux-gnu/llvm rust_source/build/x86_64-unknown-linux-gnu/llvm

Disabling SSE2.
  At the time of writing, it seems that SymCC does not support certain
  SSE2 instructions. We consequently disable by hand respective SSE2
  optimizing parts of RustC. Note that this disabling is mostly semantic
  conservative: at run-time, the behavior of the overall RustC compiler
  should be identical whenever the patch is applied or not — i.e. the
  patch can be thought of as only impacting the bootstrap time of RustC.

  Disabling SSE2 is more than desirable here for us to be able to later
  do concolic execution on Rust programs, especially on programs of size
  greater than 16 bytes. (Otherwise, a run-time error would be raised
  when trying to apply the future-built SymRustC compiler on programs of
  length larger than 16 bytes.)

Forcing stage 2.
  At the time of writing, the bootstrap of SymRustC is not made based
  using some ancestor version of SymRustC: instead, it is using a
  “traditional” ancestor version of RustC (as when bootstrapping RustC
  itself). In this case, since the compiler used at stage 0 does not
  have the ability to generate a concolic binary, we explicitly let the
  bootstrap last until at least stage 2. Note that the “stage 2
  forcing” has to be made explicit starting from RustC 1.47.0:

  - \ `https://github.com/rust-lang/rust/blob/master/RELEASES.md <https://github.com/rust-lang/rust/blob/master/RELEASES.md>`_

  - \ `https://blog.rust-lang.org/inside-rust/2020/08/30/changes-to-x-py-defaults.html <https://blog.rust-lang.org/inside-rust/2020/08/30/changes-to-x-py-defaults.html>`_

Composing with SymCC/Runtime.
  Whereas \ ``SYMCC_RUNTIME_DIR``\  has historically
  been used to specify an alternative SymCC/Runtime folder location,
  this same variable is in contrast mandatorily used to bootstrap
  SymRustC — as a temporary measure, mostly related to the reason why
  we duplicated the build of SymCC/Runtime.

.. code:: Dockerfile
  
  RUN export SYMCC_NO_SYMBOLIC_INPUT=yes \
      && cd rust_source \
      && sed -e 's/#ninja = false/ninja = true/' \
          config.toml.example > config.toml \
      && sed -i -e 's/is_x86_feature_detected!("sse2")/false \&\& &/' \
          src/librustc_span/analyze_source_file.rs \
      && export SYMCC_RUNTIME_DIR=~/symcc_build/SymRuntime-prefix/src/SymRuntime-build \
      && /usr/bin/python3 ./x.py build --stage 2



.. code:: Dockerfile
  
  ARG SYMRUSTC_RUST_BUILD=$HOME/rust_source/build/x86_64-unknown-linux-gnu
  
  ENV SYMRUSTC_CARGO=$SYMRUSTC_RUST_BUILD/stage0/bin/cargo
  ENV SYMRUSTC_RUSTC=$SYMRUSTC_RUST_BUILD/stage2/bin/rustc
  ENV SYMRUSTC_LD_LIBRARY_PATH=$SYMRUSTC_RUST_BUILD/stage2/lib
  ENV PATH=$HOME/.cargo/bin:$PATH
  
  COPY --chown=ubuntu:ubuntu --from=builder_symcc_libcxx $SYMCC_LIBCXX_PATH $SYMCC_LIBCXX_PATH
  COPY --chown=ubuntu:ubuntu src/rs/cargo.sh $SYMRUSTC_HOME_RS/
  COPY --chown=ubuntu:ubuntu src/rs/wait_all.sh $SYMRUSTC_HOME_RS/



.. code:: Dockerfile
  
  RUN mkdir symcc_build_clang \
      && ln -s ~/symcc_build/symcc symcc_build_clang/clang \
      && ln -s ~/symcc_build/sym++ symcc_build_clang/clang++

Optionally building an initial entry-point
==========================================

builder_addons: Build additional tools (using builder_symrustc)
---------------------------------------------------------------

.. code:: Dockerfile
  
  ARG SYMRUSTC_CI
  
  RUN source $SYMRUSTC_HOME_RS/wait_all.sh \
      && export SYMRUSTC_EXAMPLE=~/symcc_source/util/symcc_fuzzing_helper \
      && $SYMRUSTC_HOME_RS/cargo.sh install --path $SYMRUSTC_EXAMPLE

builder_main: Build main image (using builder_symrustc)
-------------------------------------------------------

.. code:: Dockerfile
  
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

Executing tests
***************

Testing SymCC on C++ programs
=============================

builder_examples_cpp_z3_libcxx_reg: Build concolic C++ examples - SymCC/Z3, libcxx regular (using builder_symcc_simple)
-----------------------------------------------------------------------------------------------------------------------

.. code:: Dockerfile
  
  COPY --chown=ubuntu:ubuntu src/cpp belcarra_source/src/cpp
  COPY --chown=ubuntu:ubuntu examples belcarra_source/examples
  
  RUN cd belcarra_source/examples \
      && export SYMCC_REGULAR_LIBCXX=yes \
      && $SYMRUSTC_HOME_CPP/main_fold_sym++_simple_z3.sh

builder_examples_cpp_z3_libcxx_inst: Build concolic C++ examples - SymCC/Z3, libcxx instrumented (using builder_symcc_libcxx)
-----------------------------------------------------------------------------------------------------------------------------

.. code:: Dockerfile
  
  COPY --chown=ubuntu:ubuntu src/cpp belcarra_source/src/cpp
  COPY --chown=ubuntu:ubuntu examples belcarra_source/examples
  
  RUN cd belcarra_source/examples \
      && $SYMRUSTC_HOME_CPP/main_fold_sym++_simple_z3.sh

builder_examples_cpp_qsym: Build concolic C++ examples - SymCC/QSYM (using builder_symcc_qsym)
----------------------------------------------------------------------------------------------

.. code:: Dockerfile
  
  RUN mkdir /tmp/output
  
  COPY --chown=ubuntu:ubuntu src/cpp belcarra_source/src/cpp
  COPY --chown=ubuntu:ubuntu examples belcarra_source/examples
  
  RUN cd belcarra_source/examples \
      && $SYMRUSTC_HOME_CPP/main_fold_sym++_qsym.sh

builder_examples_cpp_clang: Build concolic C++ examples - Only clang (using builder_source)
-------------------------------------------------------------------------------------------

.. code:: Dockerfile
  
  COPY --chown=ubuntu:ubuntu src/cpp belcarra_source/src/cpp
  COPY --chown=ubuntu:ubuntu examples belcarra_source/examples
  
  RUN cd belcarra_source/examples \
      && $SYMRUSTC_HOME_CPP/main_fold_clang++.sh

Testing SymRustC on Rust programs
=================================

builder_examples_rs: Build concolic Rust examples (using builder_symrustc)
--------------------------------------------------------------------------

.. code:: Dockerfile
  
  RUN sudo apt-get update \
      && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
          bsdmainutils \
      && sudo apt-get clean
  
  COPY --chown=ubuntu:ubuntu src/rs belcarra_source/src/rs
  COPY --chown=ubuntu:ubuntu examples belcarra_source/examples
  
  RUN mkdir clang_build \
      && ln -s $(which clang-$SYMRUSTC_LLVM_VERSION) clang_build/clang \
      && ln -s $(which clang++-$SYMRUSTC_LLVM_VERSION) clang_build/clang++
  
  #
  
  ARG SYMRUSTC_CI
  ARG SYMRUSTC_SKIP_FAIL
  ARG SYMRUSTC_EXAMPLE0=$HOME/belcarra_source/examples
  
  RUN cd $SYMRUSTC_EXAMPLE0 \
      && $SYMRUSTC_HOME_RS/fold_own_compiler.sh
  
  RUN cd $SYMRUSTC_EXAMPLE0 \
      && $SYMRUSTC_HOME_RS/fold_comp_result.sh

Installation Summary
********************

In summary, the following start script has been provided for the
overall build:

- \ `https://github.com/sfu-rsl/symrustc/blob/main/build_all.sh <https://github.com/sfu-rsl/symrustc/blob/main/build_all.sh>`_

License
*******

The contribution part of the project developed at Simon Fraser
University is licensed under the MIT license.

SPDX-License-Identifier: MIT
