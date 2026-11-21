#!/usr/bin/env bash
#
# Build the patched Ruby 3.2.11 base image for decidim-app.
#
# Defaults to linux/amd64 (the production cluster arch) and does NOT push.
# Set PUSH=1 to push to the registry (requires `docker login` to it first).
#
#   ./ruby-patched/build.sh            # build amd64 locally (load into docker)
#   PLATFORM=linux/arm64 ./ruby-patched/build.sh
#   PUSH=1 ./ruby-patched/build.sh     # build + push (after approval)
#   PUSH=1 PIN=1 ./ruby-patched/build.sh   # build + push, then pin the pushed
#                                          # digest into ../Dockerfile (review & commit)
#
# After pushing, the tag (ruby:3.2.11-patched) is mutable. Pin the app to the
# immutable digest so a given decidim-app commit always builds against the exact
# base it was reviewed with. The script prints the digest; PIN=1 rewrites the
# `ARG RUBY_IMAGE=` line in ../Dockerfile for you to commit.
#
set -euo pipefail

REGISTRY="${REGISTRY:-rg.fr-par.scw.cloud}"
NAMESPACE="${NAMESPACE:-decidim-app}"
IMAGE="${IMAGE:-ruby}"
TAG="${TAG:-3.2.11-patched}"
PLATFORM="${PLATFORM:-linux/amd64}"
PUSH="${PUSH:-0}"

REF="${REGISTRY}/${NAMESPACE}/${IMAGE}:${TAG}"
ctx="$(cd "$(dirname "$0")" && pwd)"

# Hash of the patch(es) baked into the image. Stamped as a label so CI
# (check_ruby_image) can assert the pinned base was built from the committed
# patch, not a stale one.
if command -v sha256sum >/dev/null 2>&1; then
  PATCH_SHA="$(cat "${ctx}"/patches/*.patch | sha256sum | awk '{print $1}')"
else
  PATCH_SHA="$(cat "${ctx}"/patches/*.patch | shasum -a 256 | awk '{print $1}')"
fi

echo "Building ${REF}"
echo "  platform:  ${PLATFORM}"
echo "  push:      ${PUSH}"
echo "  patch sha: ${PATCH_SHA}"

out_flag="--load"
if [ "${PUSH}" = "1" ]; then
  out_flag="--push"
  # buildx --load cannot hold a multi-arch manifest; --push can.
else
  # --load only supports a single platform; keep it single when not pushing.
  case "${PLATFORM}" in
    *,*) echo "error: multi-platform build needs PUSH=1 (buildx --load is single-arch)"; exit 1;;
  esac
fi

meta=""
if [ "${PUSH}" = "1" ]; then
  meta="$(mktemp)"
fi

docker buildx build \
  --platform "${PLATFORM}" \
  --tag "${REF}" \
  --label "ruby.patch.sha256=${PATCH_SHA}" \
  ${meta:+--metadata-file "${meta}"} \
  ${out_flag} \
  "${ctx}"

echo "Done: ${REF}"

if [ "${PUSH}" != "1" ]; then
  echo "Verify: docker run --rm ${REF} ruby -v"
  exit 0
fi

# Resolve the immutable digest of what we just pushed so the app can pin it.
digest="$(jq -r '."containerimage.digest" // empty' "${meta}" 2>/dev/null || true)"
if [ -z "${digest}" ]; then
  digest="$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1])).get("containerimage.digest",""))' "${meta}" 2>/dev/null || true)"
fi
rm -f "${meta}"

if [ -z "${digest}" ]; then
  echo "warning: could not read the pushed digest; resolve it manually with:"
  echo "  docker buildx imagetools inspect ${REF} --format '{{.Manifest.Digest}}'"
  exit 0
fi

pinned="${REF}@${digest}"
echo
echo "Pushed digest: ${digest}"
echo "Pin the app to this exact image by setting in ../Dockerfile:"
echo "  ARG RUBY_IMAGE=${pinned}"

if [ "${PIN:-0}" = "1" ]; then
  dockerfile="$(cd "${ctx}/.." && pwd)/Dockerfile"
  tmp="$(mktemp)"
  sed "s|^ARG RUBY_IMAGE=.*|ARG RUBY_IMAGE=${pinned}|" "${dockerfile}" > "${tmp}" && mv "${tmp}" "${dockerfile}"
  echo "Updated ${dockerfile} — review & commit the change."
fi
