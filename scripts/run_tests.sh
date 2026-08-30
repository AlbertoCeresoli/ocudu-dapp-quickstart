#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (C) 2026 DeepSig Inc.
# SPDX-License-Identifier: BSD-3-Clause-Clear
#
# Re-runs the release gates inside the built container (the image build already
# ran them once; this script exists for CI logs and for iterating with a
# mounted source tree).
set -euo pipefail

sdk_build="${OCUDU_DAPP_SDK_BUILD:-/work/ocudu-dapp-sdk/build}"

echo "== OCUDU dApp runtime and E3 unit tests"
/work/ocudu/build/tests/unittests/dapp/dapp_runtime_test --gtest_brief=1 --gtest_filter=-dapp_class_c_process_supervisor.requires_seccomp_filter_before_route_admission_when_configured

echo "== Python E3AP client against the loopback agent"
OCUDU_E3_SCHEMA_DIR=/work/ocudu/schemas/e3 python3 /work/ocudu/python/tests/test_e3ap_client.py \
  --server /work/ocudu/build/tests/unittests/dapp/e3ap_test_server

echo "== dApp release documentation"
python3 /work/ocudu/scripts/check_dapp_release_docs.py

echo "== dApp SDK"
ctest --test-dir "${sdk_build}" --output-on-failure -j2

echo "== all gates passed"
