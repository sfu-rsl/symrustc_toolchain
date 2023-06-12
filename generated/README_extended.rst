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

.. code:: shell
  
  # (* ARG *)
  if [[ ! -v SYMRUSTC_CI ]] ; then \
    echo 'Note: SYMRUSTC_CI can be exported with a particular value' >&2; \
  fi
  
  
  # (* COPY src/rs/env0.sh $SYMRUSTC_HOME_RS/ *)
  ssh localhost 'mkdir -p "'"$SYMRUSTC_HOME_RS/"'"' && \
  scp -pr "localhost:src/rs/env0.sh" "$SYMRUSTC_HOME_RS/"
  
  # (* COPY src/rs/env.sh $SYMRUSTC_HOME_RS/ *)
  ssh localhost 'mkdir -p "'"$SYMRUSTC_HOME_RS/"'"' && \
  scp -pr "localhost:src/rs/env.sh" "$SYMRUSTC_HOME_RS/"
  
  # (* COPY src/rs/parse_args0.sh $SYMRUSTC_HOME_RS/ *)
  ssh localhost 'mkdir -p "'"$SYMRUSTC_HOME_RS/"'"' && \
  scp -pr "localhost:src/rs/parse_args0.sh" "$SYMRUSTC_HOME_RS/"
  
  # (* COPY src/rs/parse_args.sh $SYMRUSTC_HOME_RS/ *)
  ssh localhost 'mkdir -p "'"$SYMRUSTC_HOME_RS/"'"' && \
  scp -pr "localhost:src/rs/parse_args.sh" "$SYMRUSTC_HOME_RS/"
  
  # (* COPY src/rs/wait_all.sh $SYMRUSTC_HOME_RS/ *)
  ssh localhost 'mkdir -p "'"$SYMRUSTC_HOME_RS/"'"' && \
  scp -pr "localhost:src/rs/wait_all.sh" "$SYMRUSTC_HOME_RS/"
  
  
  # (* RUN in a fresh session, e.g. inside `bash -c` *)
  cd ~/symcc_source/util/symcc_fuzzing_helper \
  && $SYMRUSTC_HOME_RS/env.sh $SYMRUSTC_CARGO install --path $PWD --locked

builder_extended_main: Build extended main (continuing from builder_symrustc_main)
----------------------------------------------------------------------------------

.. code:: shell
  
  # (* RUN in a fresh session, e.g. inside `bash -c` *)
  sudo apt-get update \
  && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
      build-essential \
      libllvm$SYMRUSTC_LLVM_VERSION \
      zlib1g \
  && sudo apt-get clean
  
  
  # (* RUN in a fresh session, e.g. inside `bash -c` *)
  ln -s ~/symcc_source/util/pure_concolic_execution.sh symcc_build
  
  # (* COPY --from=builder_afl $HOME/afl afl *)
  scp -pr "builder_afl:$HOME/afl" "afl"
  
  # (* COPY --from=builder_addons $HOME/.cargo .cargo *)
  scp -pr "builder_addons:$HOME/.cargo" ".cargo"
  
  
  # (* ENV *)
  export PATH=$HOME/symcc_build:$PATH
  
  
  # (* ENV *)
  export AFL_PATH=$HOME/afl
  
  # (* ENV *)
  export AFL_CC=clang-$SYMRUSTC_LLVM_VERSION
  
  # (* ENV *)
  export AFL_CXX=clang++-$SYMRUSTC_LLVM_VERSION

Testing SymCC on C++ programs
=============================

This part ensures that our internal versions of SymCC are behaving as
expected on C++ programs.

builder_examples_cpp_z3_libcxx_reg: Build concolic C++ examples - SymCC/Z3, libcxx regular (continuing from builder_symcc_simple)
---------------------------------------------------------------------------------------------------------------------------------

.. code:: shell
  
  # (* COPY src/cpp belcarra_source/src/cpp *)
  scp -pr "localhost:src/cpp" "belcarra_source/src/cpp"
  
  # (* COPY examples belcarra_source/examples *)
  scp -pr "localhost:examples" "belcarra_source/examples"
  
  
  # (* RUN in a fresh session, e.g. inside `bash -c` *)
  cd belcarra_source/examples \
  && export SYMCC_REGULAR_LIBCXX=yes \
  && $SYMRUSTC_HOME_CPP/main_fold_sym++_simple_z3.sh

builder_examples_cpp_z3_libcxx_inst: Build concolic C++ examples - SymCC/Z3, libcxx instrumented (continuing from builder_symcc_libcxx)
---------------------------------------------------------------------------------------------------------------------------------------

.. code:: shell
  
  # (* COPY src/cpp belcarra_source/src/cpp *)
  scp -pr "localhost:src/cpp" "belcarra_source/src/cpp"
  
  # (* COPY examples belcarra_source/examples *)
  scp -pr "localhost:examples" "belcarra_source/examples"
  
  
  # (* RUN in a fresh session, e.g. inside `bash -c` *)
  cd belcarra_source/examples \
  && $SYMRUSTC_HOME_CPP/main_fold_sym++_simple_z3.sh

builder_examples_cpp_qsym: Build concolic C++ examples - SymCC/QSYM (continuing from builder_symcc_qsym)
--------------------------------------------------------------------------------------------------------

.. code:: shell
  
  # (* RUN in a fresh session, e.g. inside `bash -c` *)
  mkdir /tmp/output
  
  
  # (* COPY src/cpp belcarra_source/src/cpp *)
  scp -pr "localhost:src/cpp" "belcarra_source/src/cpp"
  
  # (* COPY examples belcarra_source/examples *)
  scp -pr "localhost:examples" "belcarra_source/examples"
  
  
  # (* RUN in a fresh session, e.g. inside `bash -c` *)
  cd belcarra_source/examples \
  && $SYMRUSTC_HOME_CPP/main_fold_sym++_qsym.sh

builder_examples_cpp_clang: Build concolic C++ examples - Only clang (continuing from builder_source)
-----------------------------------------------------------------------------------------------------

.. code:: shell
  
  # (* COPY src/cpp belcarra_source/src/cpp *)
  scp -pr "localhost:src/cpp" "belcarra_source/src/cpp"
  
  # (* COPY examples belcarra_source/examples *)
  scp -pr "localhost:examples" "belcarra_source/examples"
  
  
  # (* RUN in a fresh session, e.g. inside `bash -c` *)
  cd belcarra_source/examples \
  && $SYMRUSTC_HOME_CPP/main_fold_clang++.sh

Testing SymRustC on Rust programs
=================================

We can now focus on the concolic execution of Rust programs with
SymRustC.
