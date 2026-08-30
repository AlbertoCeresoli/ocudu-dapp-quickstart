#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (C) 2026 DeepSig Inc.
# SPDX-License-Identifier: BSD-3-Clause-Clear
#
# Build the public release images from the workspace root (the directory
# holding ocudu/ and ocudu-dapp-sdk/ side by side).
#
#   ocudu-docker/scripts/build.sh                 # CPU + CUDA, 8 jobs
#   OCUDU_BUILD_VARIANT=cpu ocudu-docker/scripts/build.sh
#   OCUDU_BUILD_VARIANT=cuda OCUDU_JOBS=4 ocudu-docker/scripts/build.sh
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
for repo in ocudu ocudu-dapp-sdk; do
  if [[ ! -d "${root}/${repo}" ]]; then
    echo "missing ${root}/${repo}; run from a workspace holding ocudu/ and ocudu-dapp-sdk/" >&2
    exit 1
  fi
done

variant="${OCUDU_BUILD_VARIANT:-all}"
case "${variant}" in
  all|cpu|cuda) ;;
  *) echo "OCUDU_BUILD_VARIANT must be one of: all, cpu, cuda" >&2; exit 2 ;;
esac

common_args=(
  --file "${root}/ocudu-docker/Dockerfile"
  --build-arg "OCUDU_JOBS=${OCUDU_JOBS:-8}"
  --build-arg "OCUDU_BUILD_TYPE=${OCUDU_BUILD_TYPE:-Release}"
)
if [[ -n "${OCUDU_DOCKER_CPUSET:-}" ]]; then
  common_args+=(--cpuset-cpus "${OCUDU_DOCKER_CPUSET}")
fi

if [[ "${variant}" == all || "${variant}" == cpu ]]; then
  docker build "${common_args[@]}" \
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
  docker build "${common_args[@]}" "${cuda_args[@]}" \
    --target cuda-release \
    --tag "${OCUDU_CUDA_IMAGE_TAG:-ocudu-dapp-release:cuda-local}" \
    "${root}"
fi
