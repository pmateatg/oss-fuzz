# Don't fail silently
set -e

# Have a clean environment for Rust and LLVM build
unset CFLAGS
unset CXXFLAGS

OUR_LLVM_REVISION=cb2f0d0a5f14
OUR_RUST_VERSION=af00ff2ce #rustc 1.91.0-nightly (af00ff2ce 2025-09-04)
FUZZ_INTROSPECTOR_CHECKOUT=341ebbd72bc9116733bcfcfab5adfd7f9b633e07

#Get rustup
curl https://sh.rustup.rs | sh -s -- -y
. /rust/env

git clone --filter='blob:none' https://github.com/rust-lang/rust.git $SRC/rust
cd $SRC/rust
git checkout $OUR_RUST_VERSION
cat <<EOF >> bootstrap.toml
[llvm]
# Use the prepared patched LLVM version instead
download-ci-llvm = false
targets = "X86"

[build]
submodules = false
docs = false
# Do not query new versions of dependencies online.
locked-deps = true
sanitizers = true
profiler = true
ccache = true

[rust]
channel = "nightly"

[dist]
compression-formats = ["xz"]
compression-profile = "fast"

[install]
prefix = "/rust/rustup/toolchains/fi_chain"
EOF

# Selectively check out submodules
git submodule update --init src/tools/cargo
git submodule update --init src/tools/enzyme
git submodule update --init src/doc/reference
git submodule update --init src/doc/book
git submodule update --init library/backtrace
git submodule update --init src/tools/rustc-perf

# Checkout and reset LLVM to a compatible version of Fuzz Introspector
git clone --filter=blob:none https://github.com/llvm/llvm-project.git src/llvm-project
cd $SRC/rust/src/llvm-project
git checkout $OUR_LLVM_REVISION

echo "Applying introspector changes"
cp -rf /fuzz-introspector/frontends/llvm/include/llvm/Transforms/FuzzIntrospector/ ./llvm/include/llvm/Transforms/FuzzIntrospector
cp -rf /fuzz-introspector/frontends/llvm/lib/Transforms/FuzzIntrospector ./llvm/lib/Transforms/FuzzIntrospector

# LLVM currently does not support dynamically loading LTO passes. Thus, we
# hardcode it into Clang instead. Ref: https://reviews.llvm.org/D77704
/fuzz-introspector/frontends/llvm/patch-llvm.sh

cd $SRC/rust

export LIBRARY_PATH=/usr/local/lib/x86_64-unknown-linux-gnu/
./x build compiler tools/cargo library/std --stage 2
./x install compiler cargo std

./x dist rust-src
cd $SRC/rust/build/dist
tar -xvf rust-src-nightly.tar.xz
./rust-src-nightly/install.sh --prefix=/rust/rustup/toolchains/fi_chain --components=rust-src
cp -r /rust/rustup/toolchains/fi_chain/lib/rustlib/src /rust

rustup default fi_chain
rustup toolchain remove stable
cargo install cargo-fuzz --locked && rm -rf /rust/registry

cd $SRC

# Clean up Rust source and build only dependencies from the image
rm -rf /src/rust
apt-get autoremove --purge -y
apt-get clean