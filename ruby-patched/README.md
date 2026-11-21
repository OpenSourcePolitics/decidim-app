# Custom Ruby 3.2.11 base image

A custom Ruby base image for decidim-app. It rebuilds the Ruby that ships in the
official `ruby:3.2.11-slim` from the same 3.2.11 source with a set of additional
upstream fixes applied (Ruby 3.2 is end-of-life, so there is no newer 3.2.x
release to pick them up from). `decidim-core 0.29.5` pins
`required_ruby_version ~> 3.2.0`, so the app stays on the 3.2 series.

## What it does

`Dockerfile` starts from `ruby:3.2.11-slim`, rebuilds Ruby from the pristine
3.2.11 source with [`patches/ruby-3.2.11-upstream-fixes-2026-11.patch`](patches/)
applied, and installs it in place over `/usr/local` using the **stock image's own
`./configure` arguments** — so `--enable-shared --enable-yjit` and the
architecture triplet are preserved. `RUBY_VERSION` stays `3.2.11` and the
C-extension ABI (`3.2.0`) is unchanged, so gems built against stock 3.2.11 stay
binary-compatible.

```
ruby-patched/
├── Dockerfile    # builds the custom base image
├── build.sh      # buildx helper (amd64; push is opt-in)
└── patches/
    └── ruby-3.2.11-upstream-fixes-2026-11.patch
```

## Registry

Publishes to the **same registry decidim-app's own images use** —
`rg.fr-par.scw.cloud/decidim-app` (from the CI `vars` and the `Makefile`). The tag
consumed by the app is:

```
rg.fr-par.scw.cloud/decidim-app/ruby:3.2.11-patched
```

> Build and push only after review.

## Pinning by digest

The `:3.2.11-patched` tag is **mutable** — rebuilding and re-pushing moves it. To
keep a given decidim-app commit reproducible (it must build against the exact
base it was reviewed with, not whatever the tag points at later), pin the
**immutable digest** in the app `Dockerfile` rather than the bare tag:

```
ARG RUBY_IMAGE=rg.fr-par.scw.cloud/decidim-app/ruby:3.2.11-patched@sha256:...
```

`build.sh` prints the pushed digest after a push, and `PIN=1` rewrites the
`ARG RUBY_IMAGE=` line for you:

```bash
PUSH=1 PIN=1 ./ruby-patched/build.sh   # push, then pin the digest in ../Dockerfile
```

Review the resulting one-line change and commit it. Updating the base image is
then always an explicit, reviewable commit tied to an app version.

## Keeping the base in sync with the patch

Two guards make sure the app never builds against a base that doesn't match the
committed patch:

- **CI (authoritative)** — `build.sh` stamps the image with a
  `ruby.patch.sha256` label (the hash of `patches/*.patch`). The
  `check_ruby_image` job in `.github/workflows/ci_cd.yml` reads the pinned
  reference (tag or digest) from the app `Dockerfile`, pulls it, and asserts its
  label equals the repo's current patch hash. It is **not** a dependency of the
  test jobs — the suite runs on a Ruby that CI compiles from this patch (see
  below) — but `docker_build` (and the release push) depend on it, so the app
  image is never built against a missing or stale base.

- **Local pre-commit hook** — `.githooks/pre-commit` warns (or, when the base is
  digest-pinned, blocks) if a commit changes `patches/` without updating the
  pinned base. Install it once per clone with `make hooks`; bypass with
  `git commit --no-verify`. The hook is a fast reminder; CI is the real check.

## Running the test suite on the patched Ruby

CI does not download a prebuilt patched Ruby (none exists). The `build_ruby` job
compiles it from this same tarball + patch with
[`ci-build-ruby.sh`](ci-build-ruby.sh) (runner-native, static, no YJIT — enough
to exercise the patched interpreter), caches it keyed on the patch hash, and the
`build_app` / `tests` jobs run on it. YJIT and the production link flags are
validated by the `Dockerfile` build above, not by the test suite.

## Build

The production cluster is **linux/amd64**. On an arm64 machine, build amd64 either
under emulation (slower) or natively on an amd64 host.

```bash
# amd64, local only (no push)
./ruby-patched/build.sh

# build + push to the registry (requires docker login to the registry)
PUSH=1 ./ruby-patched/build.sh
```

`build.sh` uses `docker buildx` and defaults to `linux/amd64`.

## How the app consumes it

The app `Dockerfile`'s two `FROM` lines reference `${RUBY_IMAGE}`, defaulting to
the tag above. To build the app against a locally built base instead:

```bash
docker build --build-arg RUBY_IMAGE=decidim-ruby:3.2.11-patched -t decidim-app:local .
```

`.ruby-version`, `Gemfile.lock` (`RUBY VERSION`) and the CI `RUBY_VERSION` are set
to `3.2.11` to match (the `Gemfile`'s `ruby RUBY_VERSION` directive enforces the
lock's recorded version).
