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

The rest of the section gives more details about the installation
procedure. Although our description aims to be generic and cover most
installation corner cases, we will take Ubuntu as an illustration
example. (Note that this choice is arbitrary and may change in the
future, with for instance more emphases on OS differences and setting
to be provided.)

The code of our installation instructions will be described in
Dockerfile format
(\ `https://docs.docker.com/engine/reference/builder/ <https://docs.docker.com/engine/reference/builder/>`_\ ),
which should be syntactically pretty close to most “standard”-shell
syntax.

Semantically though, whereas the use of Docker is not mandatory, for a
reader not familiar with the Dockerfile-language, we quickly list all
Docker-commands that will be subsequently used.

Installation commands.
  \ 

  - \ ``ENV``\  exports the given variable
    in global shell-scope, so that subsequent shell-commands can use the
    exported variable, e.g. in their internal forked sub-shells.

  - \ ``ARG``\  can be thought of as being
    similar to \ ``ENV``\ , except that its scope is
    more local. Without loss of generality, it can be understood as
    being restricted to the current paragraph/subsection of discourse.

  - \ ``RUN``\  basically executes the given
    shell-command, with the possibility to use any variables prior
    exported by \ ``ENV``\  or
    \ ``ARG``\ .

  - \ ``COPY``\  can be thought of as an
    instantiated version of \ ``RUN``\  to copy files
    from one location in the filesystem to another one.

Installation build stages.
  To better organize our installation, as well as improve installation
  reusability, our installation commands can be regrouped together
  into special “named” subsections, called
  \ *build stages*\ .

  - (\ ``ARG``\ ) The scope of
    \ ``ARG``\  is actually restricted to the one of
    the build stage where it is situated.

  - (\ ``RUN``\ ) All presented build stages
    in the document will be topologically ordered, and thus have to be
    executed in specific order. It should be not wrong to just follow by
    default the sequential presentation made in the document, which has
    been tested to work well. Note that any consecutive
    \ ``RUN``\  commands are understood to be run in
    independent sub-shells: e.g. changing the current working directory
    in a \ ``RUN``\  does not affect another
    consecutive \ ``RUN``\ .

  - (\ ``COPY``\ ) Whereas the specific
    topological-dependencies are normally mentioned in the title of each
    build stage subsection, this information should not be taken as
    exclusive. For example, \ ``COPY``\  actually has
    the “meta”-ability to refer to any past build stages already
    executed in the document, using in particular the
    \ ``--from=$FROM``\  option. Consequently, a
    build stage having several \ ``COPY``\  may
    obviously create new explicit dependencies to other build stages.

Installation context.
  Certain parts of the SymRustC installation will use its source, which
  can be obtained from
  \ `https://github.com/sfu-rsl/symrustc <https://github.com/sfu-rsl/symrustc>`_\ . To refer to
  the source of SymRustC during its installation, we will have to make
  them available in our build context: this can be done with
  \ ``COPY``\ . In particular, without the
  \ ``--from=$FROM``\  option, the source path given
  \ ``COPY``\  has to be relative, and is understood
  to be relative to the SymRustC source located at the above URL.

  Note that \ ``RUN``\  does not have this same
  “meta”-contextual-ability as \ ``COPY``\ : before
  manipulating SymRustC files with \ ``RUN``\ ,
  one would have to prior copy them using
  \ ``COPY``\ .

Source preparation
==================

builder_base: Set up Ubuntu environment (continuing from ubuntu:22.04)
----------------------------------------------------------------------

Starting from a fresh Ubuntu machine, the installation will be made in
the \ ``$HOME``\  directory, and does not normally
require specific root permission. One exception though is when we use
\ ``sudo``\  with
\ ``apt-get``\  to install additional external OS
packages.

In addition to the above-mentioned docker command semantics, note
that:

- all \ ``RUN``\  used in the document will
  rely on Bash as shell
  (\ `https://www.gnu.org/software/bash/ <https://www.gnu.org/software/bash/>`_\ ).

- all \ ``COPY``\  used in the document will
  most of the time take the option
  \ ``--chown=$CHOWN``\ , which can be ignored by the
  reader. It is just a reminder signalling us that the copy can be
  proceeded in the user-space, without the root permission.

builder_source: Set up project source (continuing from builder_base)
--------------------------------------------------------------------

Certain OS may already come with some LLVM version(s) already
installed.  On the other hand, because the one we are working with is
a “predetermined” version, we have to explicitly tell the OS to try
installing it (or installing it again in case it already
exists). Besides, to be sure that our surrounding packages will use
that predetermined version, it is straightforward to implement an
option for the respective packages to force loading our intended
version, e.g. for the case of SymCC in CMakeLists syntax
(\ `https://cmake.org/cmake/help/latest/manual/cmake-commands.7.html <https://cmake.org/cmake/help/latest/manual/cmake-commands.7.html>`_\ ):

- \ `https://github.com/sfu-rsl/symcc/blob/8d3442870e6d56acd2f6bca77028d93abe8df854/CMakeLists.txt#L65 <https://github.com/sfu-rsl/symcc/blob/8d3442870e6d56acd2f6bca77028d93abe8df854/CMakeLists.txt#L65>`_

.. code:: Dockerfile
  
  ENV SYMRUSTC_LLVM_VERSION=11

Unfortunately, the above version that we give to the OS package
manager \ ``apt-get``\  is slightly different from
the one we give in CMakeLists for
\ ``cmake``\ . This is because
\ ``apt-get``\  and
\ ``cmake``\  are implementing their own
heuristic-search while looking for the initial versions requested by
the user.

One solution is to make multiple declarations for the versions of
interest (and make sure that the correct variable is provided to the
respective \ ``apt-get``\  or
\ ``cmake``\  software):

.. code:: Dockerfile
  
  ENV SYMRUSTC_LLVM_VERSION_LONG=11.1

Note that if we write “11” for the version to install in CMakeLists,
this will ultimately be understood by default as “11.0”:

- \ `https://cmake.org/cmake/help/latest/command/find_package.html#basic-signature <https://cmake.org/cmake/help/latest/command/find_package.html#basic-signature>`_

Unfortunately, “11.0” and “11.1” is considered as API-incompatible
in LLVM:

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

We can conveniently introduce the next shortcuts:

.. code:: Dockerfile
  
  ENV SYMRUSTC_HOME=$HOME/belcarra_source
  ENV SYMRUSTC_HOME_CPP=$SYMRUSTC_HOME/src/cpp
  ENV SYMRUSTC_HOME_RS=$SYMRUSTC_HOME/src/rs

Even if SymCC is not yet installed, we can enable the exportation of
this next variable so that it will be available in global scope for
the rest of the document:

.. code:: Dockerfile
  
  ENV SYMCC_LIBCXX_PATH=$HOME/libcxx_symcc_install

The first SymRustC component to install is our custom Rust
compiler. (Note that at the time of writing, our modifications mainly
intervened in the compiler bootstrap part, no significant changes
happened in the core compiling process.) Since this component has its
own git repository, the installation of this component can either be
performed through an explicit git cloning, or through the use of some
git submodule integration, made in SymRustC to keep track of the
precise Rust version. However, while copying the whole SymRustC local
source with the \ ``COPY``\  command may also be
feasible here, one can as well use a fresh clone of SymRustC instead
(e.g. for testing purposes, or miscellaneous reasons related to the
potential presence of locally modified files differing from the git
server state).

It is notably at this point where we explicitly specify the SymRustC
version to use, and it has to be mandatorily provided:

.. code:: Dockerfile
  
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

At the time of writing, the build of SymCC/Runtime is not yet
integrated to be automatically made whenever SymRustC is built. So it
has to be done manually, we first download the part corresponding to
SymCC/Runtime source inside this new folder:

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
  RUN git clone --depth 1 -b v2.56b https://github.com/google/AFL.git afl

Building SymCC/Runtime
======================

The build of the runtime part of SymCC strongly resembles to how it is
done in its original repository:

- \ `https://github.com/eurecom-s3/symcc/blob/master/Dockerfile <https://github.com/eurecom-s3/symcc/blob/master/Dockerfile>`_

builder_depend: Set up project dependencies (continuing from builder_source)
----------------------------------------------------------------------------

As prerequisite, the \ ``lit``\  binary has to be installed.

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

builder_afl: Build AFL (continuing from builder_source)
-------------------------------------------------------

Since AFL is not used by the installation phase of SymRustC, this part
can be skipped.

.. code:: Dockerfile
  
  RUN cd afl \
      && make

builder_symcc_simple: Build SymCC simple backend (continuing from builder_depend)
---------------------------------------------------------------------------------

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

builder_symcc_libcxx: Build LLVM libcxx using SymCC simple backend (continuing from builder_symcc_simple)
---------------------------------------------------------------------------------------------------------

We build the necessary SymCC/LLVM component inside the same folder
location where the build of SymRustC/LLVM will be expected to happen.

Note that here \ ``symcc``\  is used as a
“bootstrap” C compiler, whereas while bootstrapping SymRustC, we
will use the default native C compiler available, typically
\ ``cc``\ , which may not necessarily point to
\ ``symcc``\ . This may lead to numerous
consequences whenever one is trying to take advantage of incremental
compilation of LLVM, i.e. while trying to reuse the build here for
building the LLVM part of SymRustC.

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

builder_symcc_qsym: Build SymCC Qsym backend (continuing from builder_symcc_libcxx)
-----------------------------------------------------------------------------------

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

builder_symllvm: Build SymLLVM (continuing from builder_source)
---------------------------------------------------------------

Before building SymRustC, we can build its LLVM component, called here
SymLLVM. It is actually not mandatory to separate the build of SymLLVM
from SymRustC, however, doing so may make the testing of respective
components easier. Also, since some significant part of the build time
is dedicated to the build of LLVM, this separation permits the
fine-grain monitoring of each separated component and compilation-time
while drawing up benchmark statistics.

.. code:: Dockerfile
  
  COPY --chown=ubuntu:ubuntu src/llvm/cmake.sh $SYMRUSTC_HOME/src/llvm/
  
  RUN mkdir -p rust_source/build/x86_64-unknown-linux-gnu/llvm/build \
    && cd -P rust_source/build/x86_64-unknown-linux-gnu/llvm/build \
    && $SYMRUSTC_HOME/src/llvm/cmake.sh

builder_symrustc: Build SymRustC core (continuing from builder_source)
----------------------------------------------------------------------

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
  (See also:
  \ `https://github.com/eurecom-s3/symcc/issues/10 <https://github.com/eurecom-s3/symcc/issues/10>`_\ .)

  Disabling SSE2 is more than desirable here for us to be able to later
  do concolic execution on RustC, precisely when it is compiling Rust
  programs of size greater than 16 bytes. (Otherwise, a run-time error
  would be raised when trying to apply an SSE2-built SymRustC compiler
  on programs of length larger than 16 bytes.)

Forcing stage 2.
  At the time of writing, the bootstrap of SymRustC is not made based on
  some ancestor version of SymRustC: instead, it is using a
  “traditional” ancestor version of RustC (the same RustC version used
  to bootstrap RustC itself). In this case, since the compiler used at
  stage 0 does not have the ability to generate a concolic binary, we
  explicitly let the bootstrap last until at least stage 2. Note that
  the “stage 2 forcing” has to be made explicit starting from RustC
  1.47.0:

  - \ `https://github.com/rust-lang/rust/blob/master/RELEASES.md <https://github.com/rust-lang/rust/blob/master/RELEASES.md>`_

  - \ `https://blog.rust-lang.org/inside-rust/2020/08/30/changes-to-x-py-defaults.html <https://blog.rust-lang.org/inside-rust/2020/08/30/changes-to-x-py-defaults.html>`_

Composing with SymCC/Runtime.
  Whereas \ ``SYMCC_RUNTIME_DIR``\  has historically
  been used to specify an alternative SymCC/Runtime folder location, we
  chose to use this same variable to specify the location of
  SymCC/Runtime while booting SymRustC. However in contrast with SymCC
  where that variable can be optionally set, here that specification
  must be mandatorily provided (this should be a temporary measure until
  we improve the current duplicated build situation of SymCC/Runtime).

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
  ARG SYMRUSTC_RUST_BUILD_STAGE=$SYMRUSTC_RUST_BUILD/stage2
  
  ENV SYMRUSTC_CARGO=$SYMRUSTC_RUST_BUILD/stage0/bin/cargo
  ENV SYMRUSTC_RUSTC=$SYMRUSTC_RUST_BUILD_STAGE/bin/rustc
  ENV SYMRUSTC_LD_LIBRARY_PATH=$SYMRUSTC_RUST_BUILD_STAGE/lib
  ENV PATH=$HOME/.cargo/bin:$PATH
  
  COPY --chown=ubuntu:ubuntu --from=builder_symcc_libcxx $SYMCC_LIBCXX_PATH $SYMCC_LIBCXX_PATH

Certain Rust programs \ `P`\  embedding external language code (such as C
or C++) may rely on external respective compiling tools (such as
\ ``clang``\  or
\ ``clang++``\ ) during the invocation of
\ ``rustc``\  on \ `P`\ . However, to allow the
\ *full*\  enabling of concolic execution on all
parts of \ `P`\  (comprising the Rust part, as well as any other external
C or C++ parts), one would have to provide concolic counterpart
versions of respective original compilers.

For the case of \ ``clang``\  or
\ ``clang++``\ , we can do so as follows:

.. code:: Dockerfile
  
  RUN mkdir clang_symcc_on \
      && ln -s ~/symcc_build/symcc clang_symcc_on/clang \
      && ln -s ~/symcc_build/sym++ clang_symcc_on/clang++

Similarly, we provide the same disabling counterpart for a Rust
project interested to explicitly disable the concolic run on its C or
C++ implementation:

.. code:: Dockerfile
  
  RUN mkdir clang_symcc_off \
      && ln -s $(which clang-$SYMRUSTC_LLVM_VERSION) clang_symcc_off/clang \
      && ln -s $(which clang++-$SYMRUSTC_LLVM_VERSION) clang_symcc_off/clang++

Finally, it suffices to modify \ ``$PATH``\  in
such a way that SymRustC will call \ ``clang``
with (either) the necessary overloading brought by
\ ``symcc``\  (or not) — the next usage section
provides more examples and applications.

Note that certain Rust libraries may
\ *syntactically*\  check the name of the compiler
used, e.g. before applying specific optimizations depending on the
type of compiler used, so using the syntactic word
\ ``clang``\  instead of
\ ``symcc``\  is one way to avoid violating those
syntactic check!

Installation summary
********************

In summary, the following start script has been provided for building
everything presented in the document:

- \ `https://github.com/sfu-rsl/symrustc/blob/main/build_all.sh <https://github.com/sfu-rsl/symrustc/blob/main/build_all.sh>`_

Note that, at the time of writing, this script is internally assuming
that \ ``docker``\  is installed.

Usage
*****

Applying SymRustC on a single example
=====================================

builder_symrustc_main: Build SymRustC main (continuing from builder_symrustc)
-----------------------------------------------------------------------------

.. code:: Dockerfile
  
  RUN sudo apt-get update \
      && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
          bsdmainutils \
      && sudo apt-get clean
  
  COPY --chown=ubuntu:ubuntu src/rs belcarra_source/src/rs
  COPY --chown=ubuntu:ubuntu examples belcarra_source/examples

To coordinate the build and run of general Rust programs, one may
naturally want to use \ ``cargo``\ . In a concolic
setting though, one may also want to build some Rust source several
times, with different concolic build options. While ideally these
different build executions would be all automatically handled by
\ ``cargo``\ , at the time of writing they do not
look trivial to realize (without modifying the source of
\ ``cargo``\ ).

Instead, the SymRustC project is temporarily providing the following
build scripts:
\ ``$SYMRUSTC_HOME_RS/symrustc_build.sh``\  to
compile a Rust example (mostly resembling to
\ ``cargo build``\ ), and
\ ``$SYMRUSTC_HOME_RS/symrustc_run.sh``\  to run a
compiled example (mostly resembling to
\ ``cargo run``\ ). Their arguments are all
optional, and can be provided by prior exporting some custom shell
variables (e.g. using \ ``export``\ ) before
executing the respective intended binaries.

Before giving more details about the command internals and which
arguments to export, we suppose the reader already familiar with SymCC
and all its invocation options. This includes for example how to
invoke SymCC on the basic example provided in the accompanying
documentation:
\ `https://github.com/eurecom-s3/symcc/blob/master/README.md <https://github.com/eurecom-s3/symcc/blob/master/README.md>`_\ ,
what kind of back-end or solving process is performed while SymCC is
in execution, and where to find the results of the tool on the
filesystem after the tool completion.

\ ``$SYMRUSTC_HOME_RS/symrustc_build.sh``\ : description of the command
-----------------------------------------------------------------------

Any explicit arguments provided to
\ ``$SYMRUSTC_HOME_RS/symrustc_build.sh``\  are all
forwarded to our internal version of
\ ``cargo rustc --manifest-path $SYMRUSTC_DIR/Cargo.toml``
(e.g.  \ ``-- -Clinker=clang++``\  to set a
specific linker). In particular, the success of the command is partly
relying on the syntax and semantics of
\ ``$SYMRUSTC_DIR/Cargo.toml``\  (including the
presence of that file).

Our default version of \ ``cargo rustc``\  is
actually run at least twice (depending on
\ ``$SYMRUSTC_BUILD_COMP_CONCOLIC``\  subsequently
described), leading to at least two output directories:

- \ ``$SYMRUSTC_DIR/target_cargo_off``
  having the same content as what would be obtained by a “regular”
  invocation of \ ``cargo rustc``\ , i.e. without
  invoking in the end the SymCC/compiler process at the LLVM pass
  treatment, and

- \ ``$SYMRUSTC_DIR/target_cargo_on``
  containing this time the intended concolic binary after enabling the
  invocation of the SymCC/compiler.

\ ``$SYMRUSTC_HOME_RS/symrustc_build.sh``\ : description of the optional arguments to export
--------------------------------------------------------------------------------------------

- Exporting the variable
  \ ``$SYMRUSTC_DIR``\  can be used to set a specific
  compilation directory other than the current working directory (namely
  \ ``$PWD``\ ).

- Exporting the variable
  \ ``$SYMRUSTC_BUILD_COMP_CONCOLIC``\  with
  \ ``true``\  makes the concolic execution of the
  Rust compiler be performed while the compiler is compiling the
  example. (The ability to run the Rust compiler itself in concolic mode
  comes from the fact that our version of SymRustC has been partly
  bootstrapped with SymRustC — i.e. at least internally, from stage 1
  to stage 2.) By default, this option is set to
  \ ``false``\ .
  At the time of writing, the use of this option is constrained by the
  following limitations:

  - The number of Rust source to build must be no more than one.
  - The file to build must exactly be at this location:
    \ ``$SYMRUSTC_DIR/src/main.rs``\ .
  - A “regular” build with
    \ ``cargo build``\  must have prior succeeded
    in \ ``$SYMRUSTC_DIR``\  before invoking
    \ ``$SYMRUSTC_HOME_RS/symrustc_build.sh``\ ,
    also with at least all the cargo options that are statically
    written in:
    \ ``$SYMRUSTC_HOME_RS/rustc.sh``\ . (Ideally,
    these static information must be as minimal as possible.)

  Ultimately, we obtain additional compilation folders, corresponding to
  different combinations of options that may be exclusively submitted at
  a time to SymCC:

  - When \ ``$SYMCC_NO_SYMBOLIC_INPUT``\  is
    set to some value, irrespective of how the input may be provided,
    these folders are:

    - \ ``$SYMRUSTC_DIR/target_rustc_none_off``
    - \ ``$SYMRUSTC_DIR/target_rustc_none_on``

  - When the input is provided through
    \ ``$SYMCC_INPUT_FILE``\ , these folders are:

    - \ ``$SYMRUSTC_DIR/target_rustc_file_off``
    - \ ``$SYMRUSTC_DIR/target_rustc_file_on``

  - When the input is provided by a pipe from the standard input,
    these folders are:

    - \ ``$SYMRUSTC_DIR/target_rustc_stdin_off``
    - \ ``$SYMRUSTC_DIR/target_rustc_stdin_on``


  Note that each “\ ``_on``\ ” and
  “\ ``_off``\ ” folder-suffixes are re-employing
  the same conventions as the directory-names produced by the script
  when for example
  \ ``$SYMRUSTC_BUILD_COMP_CONCOLIC``\  is set to
  \ ``false``\ .

- Exporting the variable
  \ ``$SYMRUSTC_SKIP_CONCOLIC_OFF``\  with some value
  allows to skip the call to the \ ``cargo rustc``
  responsible of generating
  \ ``$SYMRUSTC_DIR/target_cargo_off``\ .

- Exporting the variable
  \ ``$SYMRUSTC_SKIP_CONCOLIC_ON``\  with some value
  allows to skip the call to the \ ``cargo rustc``
  responsible of generating
  \ ``$SYMRUSTC_DIR/target_cargo_on``\ .

\ ``$SYMRUSTC_HOME_RS/symrustc_run.sh``\ : description of the command
---------------------------------------------------------------------

While \ ``$SYMRUSTC_HOME_RS/symrustc_build.sh``
can be thought of as executing the compiler part of SymCC to compile a
high-level source for concolic execution,
\ ``$SYMRUSTC_HOME_RS/symrustc_run.sh``\  can be
basically seen as a handy wrapper to call the so-compiled concolic
binary with specific options.

Technically,
\ ``$SYMRUSTC_HOME_RS/symrustc_build.sh``\  is
producing \ *several*\  binaries, and each one may
possibly have a different concolic-power-coverage than others. To
simplify the explanation, we can however use by abuse of language
\ ``$SYMRUSTC_BIN``\  to designate one of those
binaries without mentioning which one. (In this case, in any context
where that abbreviation is used, the properties in discussion will
have to generally hold for \ *all*\  binaries.)

For example, if
\ ``$SYMRUSTC_HOME_RS/symrustc_build.sh``\  has
succeeded in producing one compiled Rust
\ ``$SYMRUSTC_BIN``\ , then an execution of
\ ``$SYMRUSTC_HOME_RS/symrustc_run.sh $input_args``
will principally have the internal effect of executing the following
shell-code:
\ ``echo $input_args | $SYMRUSTC_BIN``\  (c.f. for
instance the documentation of SymCC).

In particular, the ideal concolic-scenario is reached when
\ ``$SYMRUSTC_BIN``\  has originally been
implemented to do meaningful side-effects after receiving its input
from the standard input. If this is not the case, then the reader is
referred to the paragraph describing how one can export the variable
\ ``$SYMRUSTC_BIN_ARGS``\  for potentially covering
a more general situation.

Note that here usual options of \ ``echo``\  such
as \ ``-n``\  can be put in
\ ``$input_args``\  to better control the
appearance of the trailing newline sent to
\ ``$SYMRUSTC_BIN``\ .

The case of multiple binaries to concolic run goes by generalization:
unless otherwise noticed, we will generally not assume any specific
non-asynchronous evaluation order

- regarding the moment when each concolic run of the Rust compiler
  generating its \ ``$SYMRUSTC_BIN``\  is called
  by \ ``$SYMRUSTC_HOME_RS/symrustc_build.sh``\ ,
  or
- regarding the moment when each concolic run of
  \ ``$SYMRUSTC_BIN``\  is called by
  \ ``$SYMRUSTC_HOME_RS/symrustc_run.sh``\ .

Note that, on the other hand, some best efforts should be made by the
two scripts
\ ``$SYMRUSTC_HOME_RS/symrustc_build.sh``\  and
\ ``$SYMRUSTC_HOME_RS/symrustc_run.sh``\  for their
printed information to be sequentially presented, so that we would
best understand them. However as first experiments, it can be useful
to just ignore the standard error
\ ``2>/dev/null``\  of the two scripts.

Generally, since
\ ``$SYMRUSTC_HOME_RS/symrustc_build.sh``\  is
producing several binaries,
\ ``$SYMRUSTC_HOME_RS/symrustc_run.sh``\  is taking
care of setting \ ``$SYMCC_OUTPUT_DIR``\  to some
local path for each binary, inside each respective
\ ``$SYMRUSTC_DIR/target_*/*/*/output``
folder. So, in contrast with the default setting of SymCC, any
potential initial value of
\ ``$SYMCC_OUTPUT_DIR``\  already set in the
environment may here be ignored by SymRustC (i.e. both
\ ``$SYMRUSTC_HOME_RS/symrustc_build.sh``\  and
\ ``$SYMRUSTC_HOME_RS/symrustc_run.sh``\  may
override \ ``$SYMCC_OUTPUT_DIR``\ ).

\ ``$SYMRUSTC_HOME_RS/symrustc_run.sh``\ : description of the optional arguments to export
------------------------------------------------------------------------------------------

- Exporting the variable
  \ ``$SYMRUSTC_DIR``\  can be used to set a specific
  execution directory other than the current working directory (namely
  \ ``$PWD``\ ).

- Exporting the variable
  \ ``$SYMRUSTC_RUN_EXPECTED_CODE``\  with a non-null
  exit code will make our test framework expecting the exit code of
  (all) \ ``$SYMRUSTC_BIN``\  to be that code instead
  of the classic zero.

- Exporting the variable
  \ ``$SYMRUSTC_RUN_EXPECTED_COUNT``\  with an
  integer will make our test framework expecting the number of answers
  provided by (all) \ ``$SYMRUSTC_BIN``\  to be that
  integer. When no integer is provided, that expectation-check part will
  be skipped.

- Exporting the variable
  \ ``$SYMRUSTC_BIN_ARGS``\  with some
  space-separated parameters allows to fine-grain forward these
  parameters to \ ``$SYMRUSTC_BIN``\ .

  This is especially relevant in the unfortunate situation where
  \ ``$SYMRUSTC_BIN``\  is only reading its input
  from function-parameters (at least not from the standard input).

  For example, if the Rust binary
  \ ``$SYMRUSTC_BIN``\  is implementing the
  “classic” shell command \ ``echo``\ , called here
  \ ``echo_rs``\ , then an execution of
  \ ``echo $input_args | echo_rs $SYMRUSTC_BIN_ARGS``
  will likely not print anything noticeable in case
  \ ``$SYMRUSTC_BIN_ARGS``\  is empty (or differing
  too much from \ ``$input_args``\ ).

  At a higher level, one first tentative to remedy to the problem is to
  implicitly let \ ``echo_rs``\  forcing the read
  from its concolic-input \ ``$input_args``\  by
  setting \ ``$SYMRUSTC_BIN_ARGS``\  to lazy-read its
  standard input as follows:

  - \ ``SYMRUSTC_BIN_ARGS='$(cat /dev/stdin)' $SYMRUSTC_HOME_RS/symrustc_run.sh $input_args``

  Note the enclosing using the special quote character
  “\ ``'``\ ” instead of
  “\ ``"``\ ” to prevent a too eager evaluation
  from happening.

Applying SymRustC on multiple examples
======================================

builder_examples_rs: Build concolic Rust examples (continuing from builder_symrustc_main)
-----------------------------------------------------------------------------------------

Once that the experimenting with scripts acting on a single example is
clear:

- \ ``$SYMRUSTC_HOME_RS/symrustc_build.sh``
- \ ``$SYMRUSTC_HOME_RS/symrustc_run.sh``

the general case where we have a bunch of examples is
straightforward. This leads to:

- \ ``$SYMRUSTC_HOME_RS/fold_symrustc_build.sh``

- \ ``$SYMRUSTC_HOME_RS/fold_symrustc_run.sh``

Our Rust tests presented in this subsection have been all optimized to
take advantage of multi-core processors — at a certain expense
trade-off cost on the memory.

However, certain continuous-integration platform may differently
arrange the resource consumption made available to general users, by
prioritizing time resource over space resource. If this is the case,
then one can set the next variable to an arbitrary value before
proceeding further. Setting the variable will instruct our test to
limit as most as possible any fork operations:

.. code:: Dockerfile
  
  ARG SYMRUSTC_CI

Certain concolic execution run done by SymRustC may fail: e.g.,
whenever an instruction is not yet supported by SymCC. To avoid making
the fail interrupting our tests, we can set the next variable to an
arbitrary value:

.. code:: Dockerfile
  
  ARG SYMRUSTC_SKIP_FAIL

At this point, we are ready to start the concolic build of the
examples.

.. code:: Dockerfile
  
  RUN cd belcarra_source/examples \
      && $SYMRUSTC_HOME_RS/fold_symrustc_build.sh

Ultimately, we can proceed to the concolic execution of each
binary-result produced by the above SymRustC invocation:

.. code:: Dockerfile
  
  RUN cd belcarra_source/examples \
      && $SYMRUSTC_HOME_RS/fold_symrustc_run.sh

Extended usage (with tests)
***************************

Extended usage cases can be found in an accompanying appendix
document:

- \ `https://github.com/sfu-rsl/symrustc/blob/main/generated/README_extended.rst <https://github.com/sfu-rsl/symrustc/blob/main/generated/README_extended.rst>`_

License
*******

The contribution part of the project developed at Simon Fraser
University is licensed under the MIT license.

SPDX-License-Identifier: MIT
