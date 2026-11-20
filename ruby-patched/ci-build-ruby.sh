#!/usr/bin/env bash
#
# Compile the patched Ruby for CI test jobs, runner-native, into ~/.ruby-patched.
#
# This is NOT the production artifact. The image that ships is built by
# ruby-patched/Dockerfile (shared libruby, YJIT, the stock image's configure
# args). This build exists only so the CI test suite runs on a Ruby that carries
# the same source patch. It is a plain static build (no YJIT) because the suite
# needs the patched interpreter, not the production link flags; YJIT and the ABI
# are checked by the Dockerfile build.
#
# Reuses the exact tarball + sha256 + patch from the Dockerfile so the two builds
# stay in lockstep.
#
set -euxo pipefail

RUBY_VERSION="${RUBY_VERSION:-3.2.11}"
# sha256 of https://cache.ruby-lang.org/pub/ruby/3.2/ruby-3.2.11.tar.gz
RUBY_TARBALL_SHA256="${RUBY_TARBALL_SHA256:-b3eeabd6636f334531db3ffdc3229eb05e524740e6c84fdc043720573cf2f8b2}"
BUNDLER_VERSION="${BUNDLER_VERSION:-2.5.22}"
PREFIX="${PREFIX:-$HOME/.ruby-patched/${RUBY_VERSION}}"

here="$(cd "$(dirname "$0")" && pwd)"
patch_file="${here}/patches/ruby-${RUBY_VERSION}-upstream-fixes-2026-11.patch"

sudo apt-get update
sudo apt-get install -y --no-install-recommends \
    autoconf bison gcc make patch pkg-config \
    libssl-dev libyaml-dev zlib1g-dev libgmp-dev libffi-dev \
    wget ca-certificates

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

wget -q -O "$workdir/ruby.tar.gz" \
    "https://cache.ruby-lang.org/pub/ruby/3.2/ruby-${RUBY_VERSION}.tar.gz"
echo "${RUBY_TARBALL_SHA256}  $workdir/ruby.tar.gz" | sha256sum -c -

mkdir -p "$workdir/src"
tar -xzf "$workdir/ruby.tar.gz" -C "$workdir/src" --strip-components=1

cd "$workdir/src"
# --fuzz=0: the patch is generated against this exact tarball; refuse silent drift.
patch -p1 --fuzz=0 < "$patch_file"

./configure --prefix="$PREFIX" --disable-install-doc
make -j"$(nproc)"
make install

"$PREFIX/bin/ruby" -v
"$PREFIX/bin/gem" install "bundler:${BUNDLER_VERSION}" --no-document

echo "Patched Ruby installed at ${PREFIX}"
