#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (C) 2026 DeepSig Inc.
# SPDX-License-Identifier: BSD-3-Clause-Clear
#
# Runtime-only CUDA release gates. Run this script inside cuda-release with an
# NVIDIA device passed through; docker build itself only runs device-free gates.
set -euo pipefail

if ! nvidia-smi >/dev/null 2>&1; then
  echo "an NVIDIA GPU/driver is required; run the image with --gpus all" >&2
  exit 2
fi

echo "== host, E3, and CUDA dApp SDK"
OCUDU_DAPP_SDK_BUILD=/work/ocudu-dapp-sdk/build-cuda \
  /bin/bash /work/ocudu-docker/scripts/run_tests.sh

echo "== all CUDA release gates passed"
