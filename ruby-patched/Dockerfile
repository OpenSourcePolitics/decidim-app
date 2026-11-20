# syntax=docker/dockerfile:1
#
# Custom Ruby 3.2.11 base image for decidim-app.
#
# Rebuilds the Ruby that ships in the official `ruby:3.2.11-slim` image from the
# exact same 3.2.11 source, with a set of additional upstream fixes applied.
# Ruby 3.2 is end-of-life, so there is no newer 3.2.x release to pick them up
# from and they are carried here.
#
# The patched Ruby is installed in place over /usr/local using the stock image's
# own ./configure arguments (read back at build time), so --enable-shared,
# --enable-yjit and the build triplet are preserved per architecture.
#
ARG RUBY_BASE=ruby:3.2.11-slim
FROM ${RUBY_BASE} AS ruby-patched

ARG RUBY_VERSION=3.2.11
# sha256 of https://cache.ruby-lang.org/pub/ruby/3.2/ruby-3.2.11.tar.gz
ARG RUBY_TARBALL_SHA256=b3eeabd6636f334531db3ffdc3229eb05e524740e6c84fdc043720573cf2f8b2

SHELL ["/bin/bash", "-o", "pipefail", "-euc"]

COPY patches/ /usr/src/ruby-patches/

RUN <<'EOS'
set -euxo pipefail

savedAptMark="$(apt-mark showmanual)"

apt-get update
apt-get install -y --no-install-recommends \
    autoconf bison gcc make patch pkg-config \
    libssl-dev libyaml-dev zlib1g-dev libgmp-dev libffi-dev \
    rustc wget ca-certificates xz-utils
rm -rf /var/lib/apt/lists/*

# Reuse the stock image's exact configure arguments (arch-correct; keeps
# --enable-shared --enable-yjit). Captured BEFORE we overwrite ruby.
CONFIGURE_ARGS="$(ruby -e 'print RbConfig::CONFIG["configure_args"]')"
echo "Reusing stock configure_args:${CONFIGURE_ARGS}"

mkdir -p /usr/src/ruby
wget -q -O /tmp/ruby.tar.gz "https://cache.ruby-lang.org/pub/ruby/3.2/ruby-${RUBY_VERSION}.tar.gz"
echo "${RUBY_TARBALL_SHA256}  /tmp/ruby.tar.gz" | sha256sum -c -
tar -xzf /tmp/ruby.tar.gz -C /usr/src/ruby --strip-components=1
rm /tmp/ruby.tar.gz

cd /usr/src/ruby
# --fuzz=0: the patch is generated against this exact tarball; refuse silent drift.
patch -p1 --fuzz=0 < /usr/src/ruby-patches/ruby-3.2.11-upstream-fixes-2026-11.patch

# Rebuild + install in place over /usr/local.
eval "./configure ${CONFIGURE_ARGS} --prefix=/usr/local"
make -j"$(nproc)"
make install

cd /
rm -rf /usr/src/ruby /usr/src/ruby-patches

# Confirm the result still links and still carries YJIT.
ruby -v
ruby -e 'raise "YJIT missing" unless defined?(RubyVM::YJIT)'
ruby --yjit -e 'raise "YJIT disabled" unless RubyVM::YJIT.enabled?' && echo "YJIT OK"

# Trim back to a slim runtime: remove compilers/-dev, keep the shared runtime
# libs libruby.so links against (libssl3, libyaml-0-2, zlib1g, libgmp10, libffi8).
apt-get purge -y --auto-remove \
    autoconf bison gcc make patch pkg-config \
    libssl-dev libyaml-dev zlib1g-dev libgmp-dev libffi-dev \
    rustc wget xz-utils
rm -rf /var/lib/apt/lists/* /usr/src/*

# Restore the manual-mark set of anything that was already manual.
apt-mark manual $savedAptMark >/dev/null 2>&1 || true
EOS
