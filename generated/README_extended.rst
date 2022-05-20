.. SPDX-License-Identifier

.. Copyright (C) 2021-2022 Simon Fraser University (www.sfu.ca)

Executing tests
***************

Once the build of SymRustC is finished, we can further proceed to
miscellaneous tests and example execution.

Optionally building an initial entry-point
==========================================

This part resembles to the one present in the original SymCC
repository.

builder_addons: Build additional tools (continuing from builder_symrustc)
-------------------------------------------------------------------------

.. code:: Dockerfile
  
  ARG SYMRUSTC_CI
  
  RUN source $SYMRUSTC_HOME_RS/wait_all.sh \
      && export SYMRUSTC_EXAMPLE=~/symcc_source/util/symcc_fuzzing_helper \
      && $SYMRUSTC_HOME_RS/cargo.sh install --path $SYMRUSTC_EXAMPLE

builder_main: Build main image (continuing from builder_symrustc)
-----------------------------------------------------------------

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

Testing SymCC on C++ programs
=============================

This part ensures that our internal versions of SymCC are behaving as
expected on C++ programs.

builder_examples_cpp_z3_libcxx_reg: Build concolic C++ examples - SymCC/Z3, libcxx regular (continuing from builder_symcc_simple)
---------------------------------------------------------------------------------------------------------------------------------

.. code:: Dockerfile
  
  COPY --chown=ubuntu:ubuntu src/cpp belcarra_source/src/cpp
  COPY --chown=ubuntu:ubuntu examples belcarra_source/examples
  
  RUN cd belcarra_source/examples \
      && export SYMCC_REGULAR_LIBCXX=yes \
      && $SYMRUSTC_HOME_CPP/main_fold_sym++_simple_z3.sh

builder_examples_cpp_z3_libcxx_inst: Build concolic C++ examples - SymCC/Z3, libcxx instrumented (continuing from builder_symcc_libcxx)
---------------------------------------------------------------------------------------------------------------------------------------

.. code:: Dockerfile
  
  COPY --chown=ubuntu:ubuntu src/cpp belcarra_source/src/cpp
  COPY --chown=ubuntu:ubuntu examples belcarra_source/examples
  
  RUN cd belcarra_source/examples \
      && $SYMRUSTC_HOME_CPP/main_fold_sym++_simple_z3.sh

builder_examples_cpp_qsym: Build concolic C++ examples - SymCC/QSYM (continuing from builder_symcc_qsym)
--------------------------------------------------------------------------------------------------------

.. code:: Dockerfile
  
  RUN mkdir /tmp/output
  
  COPY --chown=ubuntu:ubuntu src/cpp belcarra_source/src/cpp
  COPY --chown=ubuntu:ubuntu examples belcarra_source/examples
  
  RUN cd belcarra_source/examples \
      && $SYMRUSTC_HOME_CPP/main_fold_sym++_qsym.sh

builder_examples_cpp_clang: Build concolic C++ examples - Only clang (continuing from builder_source)
-----------------------------------------------------------------------------------------------------

.. code:: Dockerfile
  
  COPY --chown=ubuntu:ubuntu src/cpp belcarra_source/src/cpp
  COPY --chown=ubuntu:ubuntu examples belcarra_source/examples
  
  RUN cd belcarra_source/examples \
      && $SYMRUSTC_HOME_CPP/main_fold_clang++.sh

Testing SymRustC on Rust programs
=================================

We can now focus on the concolic execution of Rust programs with
SymRustC.

builder_examples_rs: Build concolic Rust examples (continuing from builder_symrustc)
------------------------------------------------------------------------------------

.. code:: Dockerfile
  
  RUN sudo apt-get update \
      && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
          bsdmainutils \
      && sudo apt-get clean
  
  COPY --chown=ubuntu:ubuntu src/rs belcarra_source/src/rs
  COPY --chown=ubuntu:ubuntu examples belcarra_source/examples

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

At this point, we are ready to start the concolic execution using
SymRustC.

Due to the fact that our version of SymRustC has been bootstrapped
with SymRustC (at least internally, e.g. from stage 1 to stage 2), we
can start the tests by performing the concolic execution on the own
source of RustC (while \ ``rustc``\  is instructed
to compile our test examples):

.. code:: Dockerfile
  
  ARG SYMRUSTC_EXAMPLE0=$HOME/belcarra_source/examples
  
  RUN $SYMRUSTC_HOME_RS/fold_symrustc_build.sh

Ultimately, we can proceed to the concolic execution of each
binary-compiled-result produced by each respective SymRustC invocation
(obtained above from \ ``rustc``\ ):

.. code:: Dockerfile
  
  RUN $SYMRUSTC_HOME_RS/fold_symrustc_run.sh
