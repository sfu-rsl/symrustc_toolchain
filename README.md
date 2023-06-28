# SymRustC
SymRustC is a hybrid fuzzer for Rust combining concolic execution
using [SymCC](https://github.com/eurecom-s3/symcc) and fuzzing using
[LibAFL](https://github.com/AFLplusplus/LibAFL).

SymRustC can be viewed as being composed of two components: the first
component being a pure concolic engine, and the second a hybrid
engine, involving concolic execution and fuzzing. Consequently, the
second component is partly depending on the first component.

This repository provides some renovation on the pure concolic engine,
particularly regarding the ease of installation of SymRustC. It
nevertheless keeps the same usage functionalities, features and
limitations of our original implementation. Note that at the time of
writing, the hybrid component is not yet using this renovation
repository, as the integration and merge might not be straightforward.

This repository only focuses on the installation and use of the pure
concolic engine. For the hybrid usage, we invite the user to refer to
the original repository of SymCC:
[https://github.com/sfu-rsl/symrustc](https://github.com/sfu-rsl/symrustc).

The easiest way to try out the pure concolic engine of SymRustC is
through the docker image available at
`ghcr.io/sfu-rsl/symrustc:latest`. This image consists of two
`rustup` toolchains, one called `normal` (default) that contains a
regular build of the Rust compiler, and another called `symrustc` that
symbolizes your Rust projects during the compilation giving a result
that is concolically executable.

### Example
```console
$ docker pull ghcr.io/sfu-rsl/symrustc
$ docker run -it --rm ghcr.io/sfu-rsl/symrustc

ubuntu@xxxx:~$ cd examples/source_0_original_1a_rs/
ubuntu@xxxx:~$ rustup override set symrustc
ubuntu@xxxx:~$ cargo run
```
You can set `symrustc` as your toolchain through other ways as well.
For example, to make `symrustc` the default toolchain globally, you
can run the following command:
```console
ubuntu@xxxx:~$ rustup default symrustc
```
To see other options, check out [this
section](https://rust-lang.github.io/rustup/overrides.html) in the
`rustup` book.

The environment also provide the commands `symrustc` and `symcargo`
which work as a drop-in respectively for `rustc` and `cargo`.
```console
ubuntu@xxxx:~$ symrustc ./main.rs
ubuntu@xxxx:~$ ./main
```

### Configuration
By nature, the programs compiled by SymRustC respect the runtime
configuration variables meant for SymCC.

In addition, you can set the following environment variables for
changing the behavior of `symrustc` compiler.
| **Variable**           | **Purpose**                                                                                           | **Default Value**                             |
|------------------------|-------------------------------------------------------------------------------------------------------|-----------------------------------------------|
| `SYMRUSTC_RUSTC`       | Determines the path to the Rust compiler that supports SymCC's pass.                                  | `rustc` in the `normal` toolchain             |
| `SYMRUSTC_SYMSTD`      | Determines the [`sysroot`](https://doc.rust-lang.org/rustc/command-line-arguments.html#--sysroot-override-the-system-root) for `symrustc`. Used for setting a symbolized version of built-in libraries. | `symrustc`'s toolchain path                   |
| `SYMRUSTC_RUNTIME_DIR` | Equivalent to `SYMCC_RUNTIME_DIR`.                                                                    | The QSYM runtime library's path in the image. |

For more information about the configurations and symbolic execution
output please refer to [SymCC](eurecom-s3/symcc)'s documentations.

# License

The contribution part of the project developed at Simon Fraser
University is licensed under the MIT license.

SPDX-License-Identifier: MIT

# Publication

[Frédéric Tuong](https://www.sfu.ca/~ftuong/), [Mohammad Omidvar Tehrani](https://orcid.org/0009-0004-0078-0366), [Marco Gaboardi](https://cs-people.bu.edu/gaboardi/), and [Steven Y. Ko](https://steveyko.github.io/). 2023. SymRustC: A Hybrid Fuzzer for Rust (Tool Demonstrations Track). In [Proceedings of the 32nd ACM SIGSOFT International Symposium on Software Testing and Analysis (ISSTA '23)](https://2023.issta.org/track/issta-2023-tool-demonstrations), July 17–21, 2023, Seattle, WA, USA. ACM, New York, NY, USA, 4 pages. [https://doi.org/10.1145/3597926.3604927](https://doi.org/10.1145/3597926.3604927)
