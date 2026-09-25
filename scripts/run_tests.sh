#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (C) 2026 DeepSig Inc.
# SPDX-License-Identifier: BSD-3-Clause-Clear
#
# The CPU release gates. The image build runs them (`host` after the platform
# build, `sdk` after the SDK build); run them again inside the finished image
# for CI logs or when iterating with a mounted source tree:
#
#   bash /work/ocudu-docker/scripts/run_tests.sh              # host and sdk
#   bash /work/ocudu-docker/scripts/run_tests.sh host
#
# The E3 transports run over SCTP, which comes from the kernel of the machine
# running the container (`sudo modprobe sctp`). Without it, the SCTP transport
# tests, the Python E3 client test and the SDK examples' live E3 checks are
# skipped with a notice and everything else runs; OCUDU_REQUIRE_SCTP=1 turns a
# missing SCTP into a failure.
set -euo pipefail

sdk_build="${OCUDU_DAPP_SDK_BUILD:-/work/ocudu-dapp-sdk/build}"
test_server=/work/ocudu/build/tests/unittests/dapp/e3ap_test_server
sections=("$@")
if [[ ${#sections[@]} -eq 0 ]]; then
  sections=(host sdk)
fi

if python3 -c "import socket; socket.socket(socket.AF_INET, socket.SOCK_STREAM, socket.IPPROTO_SCTP).close()" 2>/dev/null; then
  sctp=true
elif [[ "${OCUDU_REQUIRE_SCTP:-0}" == 1 ]]; then
  echo "SCTP sockets are unavailable in this kernel and OCUDU_REQUIRE_SCTP=1; load the sctp module (sudo modprobe sctp)." >&2
  exit 1
else
  sctp=false
  echo "!! SCTP sockets are unavailable in this kernel: skipping the E3 SCTP transport tests, the Python"
  echo "!! E3 client test and the SDK examples' live E3 checks. Load the sctp module (sudo modprobe sctp)"
  echo "!! to run them, or set OCUDU_REQUIRE_SCTP=1 to make this an error."
fi

run_host() {
  echo "== gNB binary"
  /work/ocudu/build/apps/gnb/gnb --version

  echo "== OCUDU dApp runtime and E3 unit tests"
  local excluded=dapp_class_c_process_supervisor.requires_seccomp_filter_before_route_admission_when_configured
  if [[ "${sctp}" != true ]]; then
    excluded+=":dapp_e3ap_sctp_server.*:dapp_e3dp_sctp_server.*"
  fi
  /work/ocudu/build/tests/unittests/dapp/dapp_runtime_test --gtest_brief=1 "--gtest_filter=-${excluded}"

  echo "== Python E3AP client against the loopback agent"
  if [[ "${sctp}" == true ]]; then
    OCUDU_E3_SCHEMA_DIR=/work/ocudu/schemas/e3 python3 /work/ocudu/python/tests/test_e3ap_client.py \
      --server "${test_server}"
  else
    echo "skipped: needs SCTP"
  fi

  echo "== dApp release documentation"
  python3 /work/ocudu/scripts/check_dapp_release_docs.py
}

run_sdk() {
  echo "== dApp SDK (reference packages, tools, and the E3 examples against the loopback agent)"
  if [[ "${sctp}" == true ]]; then
    OCUDU_E3AP_TEST_SERVER="${test_server}" ctest --test-dir "${sdk_build}" --output-on-failure -j2
  else
    ctest --test-dir "${sdk_build}" --output-on-failure -j2
  fi
}

for section in "${sections[@]}"; do
  case "${section}" in
    host) run_host ;;
    sdk) run_sdk ;;
    *) echo "unknown section ${section}; expected host or sdk" >&2; exit 2 ;;
  esac
done
if [[ "${sctp}" == true ]]; then
  echo "== all gates passed"
else
  echo "== all gates passed (E3 over SCTP skipped: no SCTP in this kernel)"
fi
