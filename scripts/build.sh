#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (C) 2026 DeepSig Inc.
# SPDX-License-Identifier: BSD-3-Clause-Clear
#
# Build the public release images from the workspace root (the directory
# holding ocudu/, ocudu-dapp-sdk/ and ocudu-docker/ side by side; see
# fetch_sources.sh).
#
#   ocudu-docker/scripts/build.sh                 # CPU + CUDA, 8 jobs
#   OCUDU_BUILD_VARIANT=cpu ocudu-docker/scripts/build.sh
#   OCUDU_BUILD_VARIANT=cuda OCUDU_JOBS=4 ocudu-docker/scripts/build.sh
#   OCUDU_DOCKER_CPUSET=5-9,14 OCUDU_JOBS=6 ocudu-docker/scripts/build.sh
#
# OCUDU_DOCKER_CPUSET confines the whole build to those CPUs, e.g. to keep a
# gNB on the same host undisturbed. BuildKit ignores `docker build
# --cpuset-cpus`, so the build then runs in a dedicated buildx builder
# (docker-container driver) created with that CPU set and loads the images into
# the local image store.
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
for repo in ocudu ocudu-dapp-sdk ocudu-docker; do
  if [[ ! -d "${root}/${repo}" ]]; then
    echo "missing ${root}/${repo}; run fetch_sources.sh, or build from a workspace holding" \
      "ocudu/, ocudu-dapp-sdk/ and ocudu-docker/" >&2
    exit 1
  fi
done

variant="${OCUDU_BUILD_VARIANT:-all}"
case "${variant}" in
  all|cpu|cuda) ;;
  *) echo "OCUDU_BUILD_VARIANT must be one of: all, cpu, cuda" >&2; exit 2 ;;
esac

# Source revisions for the image labels: the checkouts themselves, else the sources.env that
# fetch_sources.sh wrote (a workspace of exported trees).
recorded_platform=unknown
recorded_sdk=unknown
if [[ -f "${root}/sources.env" ]]; then
  recorded_platform="$(sed -n 's/^OCUDU_PLATFORM_REVISION=//p' "${root}/sources.env")"
  recorded_sdk="$(sed -n 's/^OCUDU_SDK_REVISION=//p' "${root}/sources.env")"
fi
platform_revision="$(git -C "${root}/ocudu" rev-parse HEAD 2>/dev/null || echo "${recorded_platform}")"
sdk_revision="$(git -C "${root}/ocudu-dapp-sdk" rev-parse HEAD 2>/dev/null || echo "${recorded_sdk}")"
echo "platform ${platform_revision}, SDK ${sdk_revision}"

build=(docker build)
if [[ -n "${OCUDU_DOCKER_CPUSET:-}" ]]; then
  builder="ocudu-cpuset-${OCUDU_DOCKER_CPUSET//[^0-9]/-}"
  if ! docker buildx inspect "${builder}" >/dev/null 2>&1; then
    docker buildx create --name "${builder}" --driver docker-container \
      --driver-opt "\"cpuset-cpus=${OCUDU_DOCKER_CPUSET}\"" >/dev/null
  fi
  build=(docker buildx build --builder "${builder}" --load)
fi

common_args=(
  --file "${root}/ocudu-docker/Dockerfile"
  --build-arg "OCUDU_JOBS=${OCUDU_JOBS:-8}"
  --build-arg "OCUDU_BUILD_TYPE=${OCUDU_BUILD_TYPE:-Release}"
  --build-arg "OCUDU_PLATFORM_REVISION=${platform_revision}"
  --build-arg "OCUDU_SDK_REVISION=${sdk_revision}"
)
if [[ -n "${OCUDU_DOCKER_BUILD_ARGS:-}" ]]; then
  # Extra `docker build` arguments, e.g. --progress=plain or cache options in CI.
  read -r -a extra <<< "${OCUDU_DOCKER_BUILD_ARGS}"
  common_args+=("${extra[@]}")
fi

if [[ "${variant}" == all || "${variant}" == cpu ]]; then
  "${build[@]}" "${common_args[@]}" \
    --target cpu-release \
    --tag "${OCUDU_CPU_IMAGE_TAG:-ocudu-dapp-release:cpu-local}" \
    "${root}"
fi

if [[ "${variant}" == all || "${variant}" == cuda ]]; then
  cuda_args=(
    --build-arg "OCUDU_CUDA_ARCHITECTURES=${OCUDU_CUDA_ARCHITECTURES:-89-real;90-real;121}"
  )
  if [[ -n "${OCUDU_CUDA_IMAGE:-}" ]]; then
    cuda_args+=(--build-arg "CUDA_IMAGE=${OCUDU_CUDA_IMAGE}")
  fi
  "${build[@]}" "${common_args[@]}" "${cuda_args[@]}" \
    --target cuda-release \
    --tag "${OCUDU_CUDA_IMAGE_TAG:-ocudu-dapp-release:cuda-local}" \
    "${root}"
fi
