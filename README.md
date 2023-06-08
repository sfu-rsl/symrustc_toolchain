# SymRustC
SymRustC is an integration of the concolic execution tool [SymCC](eurecom-s3/symcc) into the Rust build system.

The easiest way to try out SymRustC is through the docker image available at `ghcr.io/sfu-rsl/symrustc:latest`.
This image consists of two `rustup` toolchains,
one called `normal` (default) that contains a regular build of the Rust compiler,
and another called `symrustc` that symbolizes your Rust projects during the compilation giving a result that is
concolically executable.

### Example
```console
$ docker pull ghcr.io/sfu-rsl/symrustc
$ docker run -it --rm ghcr.io/sfu-rsl/symrustc

ubuntu@xxxx:~$ cd examples/source_0_original_1a_rs/
ubuntu@xxxx:~$ rustup override set symrustc
ubuntu@xxxx:~$ cargo run
```
You can set `symrustc` as your toolchain through other ways as well.
Please refer to the [official documentation](https://rust-lang.github.io/rustup/overrides.html) of `rustup`.

The environment also provide the commands `symrustc` and `symcargo` which work as a drop-in respectively for `rustc` and `cargo`.
```console
ubuntu@xxxx:~$ symrustc ./main.rs
ubuntu@xxxx:~$ ./main
```

### Configuration
By nature, the programs compiled by SymRustC respect the runtime configuration variables meant for SymCC.

In addition, you can set the following environment variables for changing the behavior of `symrustc` compiler.
| **Variable**           | **Purpose**                                                                                          | **Default Value**                             |
|------------------------|------------------------------------------------------------------------------------------------------|-----------------------------------------------|
| `SYMRUSTC_RUSTC`       | Determines the path to the normal rust compiler that supports SymCC's pass.                          | `rustc` in the `normal` toolchain             |
| `SYMRUSTC_SYMSTD`      | Determines the `sysroot` of `symrustc`. Used for setting a symbolized version of built-in libraries. | `symrustc`'s toolchain path                   |
| `SYMRUSTC_RUNTIME_DIR` | Equivalent to `SYMCC_RUNTIME_DIR`.                                                                   | The QSYM runtime library's path in the image. |

For more information about the configurations and symbolic execution output please refer to [SymCC](eurecom-s3/symcc)'s documentations.

# SymRustC: Presentation

SymRustC is a tool implemented in the Belcarra project
(<https://github.com/sfu-rsl>) for practical and efficient symbolic
execution of Rust programs.

Demo video: <https://www.youtube.com/watch?v=ySIWT2CDi40>

# License

The contribution part of the project developed at Simon Fraser
University is licensed under the MIT license.

SPDX-License-Identifier: MIT
