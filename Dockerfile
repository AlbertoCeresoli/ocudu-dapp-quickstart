# syntax=docker/dockerfile:1.7
# SPDX-FileCopyrightText: Copyright (C) 2026 DeepSig Inc.
# SPDX-License-Identifier: BSD-3-Clause-Clear
#
# Reproducible build of the public OCUDU dApp/E3 release set: the OCUDU host
# (dApp runtime, embedded E3 agent, SCTP carriers, gNB binary) and the
# standalone dApp SDK, with radio support (UHD split-8, split-7.2 Open
# Fronthaul, DPDK fronthaul backend) built in. The cpu-release target is
# portable; cuda-release additionally compiles a CUDA-accelerated gNB host
# and the CUDA reference packages for the supported GPUs.
# Only the two public repositories are used; vendor-internal packages layer
# their own image on top of these targets from a separate overlay.
#
# Build context: the workspace that contains ./ocudu (ocudu-dapp-platform),
# ./ocudu-dapp-sdk and ./ocudu-docker side by side; scripts/fetch_sources.sh
# clones the public repositories into that layout (main by default).
#
#   docker build --target cpu-release -f ocudu-docker/Dockerfile \
#     -t ocudu-dapp-release:cpu .
#   docker build --target cuda-release -f ocudu-docker/Dockerfile \
#     -t ocudu-dapp-release:cuda .
#
# GPU execution gates run after image construction with `docker run --gpus all`;
# an ordinary image build intentionally does not assume access to a host GPU.

ARG UBUNTU_TAG=24.04
ARG CUDA_IMAGE=nvidia/cuda:13.0.1-devel-ubuntu24.04
FROM ubuntu:${UBUNTU_TAG} AS toolchain

ARG DEBIAN_FRONTEND=noninteractive
ARG ASN1C_REPOSITORY=https://github.com/mouse07410/asn1c.git
# Pinned asn1c fork commit with the APER generator used by the release.
ARG ASN1C_COMMIT=844f9ca

RUN apt-get update && apt-get install --no-install-recommends -y \
    ca-certificates git curl pkg-config \
    build-essential ccache clang cmake ninja-build \
    autoconf automake libtool bison flex \
    flatbuffers-compiler libflatbuffers-dev libgtest-dev libgmock-dev \
    libboost-program-options-dev libconfig++-dev libfftw3-dev \
    libmbedtls-dev libsctp-dev lksctp-tools libyaml-cpp-dev \
    libzmq3-dev libnuma-dev libssl-dev libpcap-dev nlohmann-json3-dev \
    libuhd-dev uhd-host libdpdk-dev \
    doxygen graphviz \
    python3 python3-pip python3-venv python3-numpy python3-h5py python3-yaml \
  && rm -rf /var/lib/apt/lists/*

# asn1c with Aligned PER support (the distribution package lacks -gen-APER).
RUN git clone --depth 200 "${ASN1C_REPOSITORY}" /opt/src/asn1c \
  && cd /opt/src/asn1c && git checkout "${ASN1C_COMMIT}" \
  && test -f configure.ac && autoreconf -iv \
  && ./configure --prefix=/opt/asn1c \
  && make -j"$(nproc)" && make install \
  && /opt/asn1c/bin/asn1c -v | head -1

# Python side: schema tooling for the codecs and the public test/replay tools.
# (Overlay images add their own runtime deps on top of this venv.)
RUN python3 -m venv /opt/venv \
  && /opt/venv/bin/pip install --no-cache-dir --upgrade pip \
  && /opt/venv/bin/pip install --no-cache-dir \
    asn1tools numpy h5py pyzmq flatbuffers PyYAML
ENV PATH=/opt/venv/bin:/opt/asn1c/bin:${PATH}

# ---------------------------------------------------------------------------
FROM toolchain AS ocudu-host

ARG OCUDU_BUILD_TYPE=Release
ARG OCUDU_JOBS=8
WORKDIR /work
COPY ocudu /work/ocudu

# clang is used for ocudu: on aarch64 the channel-coding CMake refuses GCC with
# -march=native (no +crypto), and clang works uniformly on x86-64 and arm64.
# Radio support is built into every image: UHD for split-8 USRPs, split-7.2
# Open Fronthaul on the kernel raw-socket transport, and the DPDK fronthaul
# backend (Ubuntu 24.04 libdpdk). Backend selection stays in the gNB YAML.
ARG OCUDU_C_COMPILER=clang
ARG OCUDU_CXX_COMPILER=clang++
RUN --mount=type=cache,id=ocudu-host-ccache,target=/root/.cache/ccache \
    cmake -S /work/ocudu -B /work/ocudu/build -G Ninja \
      -DCMAKE_C_COMPILER=${OCUDU_C_COMPILER} -DCMAKE_CXX_COMPILER=${OCUDU_CXX_COMPILER} \
      -DCMAKE_C_COMPILER_LAUNCHER=ccache -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
      -DCMAKE_BUILD_TYPE=${OCUDU_BUILD_TYPE} \
      -DENABLE_DAPP=ON -DENABLE_E3=ON -DENABLE_E3_ASN1_CODEC=ON \
      -DASN1C_EXECUTABLE=/opt/asn1c/bin/asn1c \
      -DENABLE_UHD=ON -DENABLE_DPDK=ON \
      -DENABLE_ZEROMQ=OFF \
      -DENABLE_MKL=OFF -DENABLE_ARMPL=OFF -DENABLE_PLUGINS=OFF -DENABLE_CUDA=OFF \
  && cmake --build /work/ocudu/build --parallel ${OCUDU_JOBS} --target \
      gnb ocudu-dappctl ocudu-dapp-preflight ocudu-dapp-package ocudu-pusch-replay \
      dapp_runtime_test e3ap_test_server \
  && cmake --install /work/ocudu/build --prefix /opt/ocudu --component dapp_sdk

# Host gates that cover the release surface touched by the E3 work. The E3
# transports need SCTP from the build machine's kernel; without it those gates
# are skipped with a notice, and OCUDU_REQUIRE_SCTP=1 makes that a failure.
ARG OCUDU_REQUIRE_SCTP=0
COPY --chmod=0755 ocudu-docker/scripts/run_tests.sh /work/ocudu-docker/scripts/run_tests.sh
RUN OCUDU_REQUIRE_SCTP=${OCUDU_REQUIRE_SCTP} /work/ocudu-docker/scripts/run_tests.sh host

# ---------------------------------------------------------------------------
FROM ocudu-host AS dapp-sdk

ARG OCUDU_JOBS=8
ARG OCUDU_REQUIRE_SCTP=0
COPY ocudu-dapp-sdk /work/ocudu-dapp-sdk
RUN --mount=type=cache,id=ocudu-sdk-cpu-ccache,target=/root/.cache/ccache \
    cmake -S /work/ocudu-dapp-sdk -B /work/ocudu-dapp-sdk/build -G Ninja \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_C_COMPILER_LAUNCHER=ccache -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
      -DCMAKE_PREFIX_PATH=/opt/ocudu \
      -DOCUDU_DAPP_BUILD_CUDA_EXAMPLES=OFF \
      -DOCUDU_DAPP_BUILD_PYTHON_CLASS_C=OFF \
      -DOCUDU_DAPP_REF_EXTRAS=ON \
      -DOCUDU_DAPP_REQUIRE_ABI_COMPILER_MATRIX=ON \
      -DOCUDU_DAPP_REQUIRE_PYTHON_EXAMPLES=ON \
  && cmake --build /work/ocudu-dapp-sdk/build --parallel ${OCUDU_JOBS} \
  && OCUDU_REQUIRE_SCTP=${OCUDU_REQUIRE_SCTP} /work/ocudu-docker/scripts/run_tests.sh sdk \
  && cmake --install /work/ocudu-dapp-sdk/build --prefix /opt/ocudu

# ---------------------------------------------------------------------------
# Stable public name for the portable image.
FROM dapp-sdk AS cpu-release

# Which sources the image was built from (scripts/build.sh passes them from
# the workspace's sources.env or the checkouts themselves).
ARG OCUDU_PLATFORM_REVISION=unknown
ARG OCUDU_SDK_REVISION=unknown
LABEL org.opencontainers.image.title="OCUDU dApp release" \
      org.opencontainers.image.source="https://gitlab.com/ocudu/work_groups/wg2_ai_ran/ocudu-dapp-quickstart" \
      org.ocudu.platform.revision="${OCUDU_PLATFORM_REVISION}" \
      org.ocudu.sdk.revision="${OCUDU_SDK_REVISION}"

COPY --chmod=0755 ocudu-docker/scripts /work/ocudu-docker/scripts
COPY ocudu-docker/examples /work/ocudu-docker/examples

# Empty dApp catalog the example configs point at (drop vendor bundles here,
# or bind-mount your own catalog over it) plus the runtime socket directory.
RUN mkdir -p /opt/ocudu/dapps /run/ocudu

ENV OCUDU_E3_SCHEMA_DIR=/work/ocudu/schemas/e3 \
    OCUDU_E3_PYTHON_DIR=/work/ocudu/python \
    PYTHONPATH=/work/ocudu/python
WORKDIR /work
CMD ["/bin/bash"]

# ---------------------------------------------------------------------------
# CUDA compilation toolchain. Build-time CUDA does not require /dev/nvidia*;
# runtime validation is deliberately kept in scripts/run_cuda_tests.sh.
FROM ${CUDA_IMAGE} AS cuda-toolchain

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install --no-install-recommends -y \
    ca-certificates git curl pkg-config \
    build-essential ccache clang cmake ninja-build \
    autoconf automake libtool bison flex \
    flatbuffers-compiler libflatbuffers-dev libgtest-dev libgmock-dev \
    libboost-program-options-dev libconfig++-dev libfftw3-dev \
    libmbedtls-dev libsctp-dev lksctp-tools libyaml-cpp-dev \
    libzmq3-dev libnuma-dev libssl-dev libpcap-dev nlohmann-json3-dev \
    libuhd-dev uhd-host libdpdk-dev \
    doxygen graphviz \
    python3 python3-pip python3-venv python3-numpy python3-h5py python3-yaml \
  && rm -rf /var/lib/apt/lists/*

COPY --from=toolchain /opt/asn1c /opt/asn1c
COPY --from=toolchain /opt/venv /opt/venv
ENV PATH=/opt/venv/bin:/opt/asn1c/bin:${PATH}

# ---------------------------------------------------------------------------
# OCUDU host rebuilt with the CUDA-accelerated L1: the same configuration as
# ocudu-host (radio support included) plus ENABLE_CUDA, so the CUDA image runs
# an accelerated gNB directly. Compilation needs no GPU; runtime does.
FROM cuda-toolchain AS cuda-host

ARG OCUDU_BUILD_TYPE=Release
ARG OCUDU_JOBS=8
ARG OCUDU_CUDA_ARCHITECTURES=89-real;90-real;121
ARG OCUDU_C_COMPILER=clang
ARG OCUDU_CXX_COMPILER=clang++
WORKDIR /work
COPY ocudu /work/ocudu
RUN --mount=type=cache,id=ocudu-cuda-host-ccache,target=/root/.cache/ccache \
    cmake -S /work/ocudu -B /work/ocudu/build -G Ninja \
      -DCMAKE_C_COMPILER=${OCUDU_C_COMPILER} -DCMAKE_CXX_COMPILER=${OCUDU_CXX_COMPILER} \
      -DCMAKE_C_COMPILER_LAUNCHER=ccache -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
      -DCMAKE_CUDA_COMPILER_LAUNCHER=ccache \
      -DCMAKE_BUILD_TYPE=${OCUDU_BUILD_TYPE} \
      "-DCMAKE_CUDA_ARCHITECTURES=${OCUDU_CUDA_ARCHITECTURES}" \
      -DENABLE_DAPP=ON -DENABLE_E3=ON -DENABLE_E3_ASN1_CODEC=ON \
      -DASN1C_EXECUTABLE=/opt/asn1c/bin/asn1c \
      -DENABLE_UHD=ON -DENABLE_DPDK=ON \
      -DENABLE_ZEROMQ=OFF \
      -DENABLE_MKL=OFF -DENABLE_ARMPL=OFF -DENABLE_PLUGINS=OFF -DENABLE_CUDA=ON \
  && cmake --build /work/ocudu/build --parallel ${OCUDU_JOBS} --target \
      gnb ocudu-dappctl ocudu-dapp-preflight ocudu-dapp-package ocudu-pusch-replay \
      dapp_runtime_test e3ap_test_server \
  && cmake --install /work/ocudu/build --prefix /opt/ocudu --component dapp_sdk

# ---------------------------------------------------------------------------
# Full CUDA SDK and reference catalog on the CUDA-accelerated host. The public
# dApp ABI is backend-neutral; the SDK validates against the installed host.
FROM cuda-toolchain AS cuda-release

ARG OCUDU_JOBS=8
# RTX 4090, GH200 and GB10. The final architecture also carries PTX so a newer
# compatible driver may JIT it; callers can override this list at build time.
ARG OCUDU_CUDA_ARCHITECTURES=89-real;90-real;121

WORKDIR /work
COPY --from=cuda-host /work/ocudu /work/ocudu
COPY --from=cuda-host /opt/ocudu /opt/ocudu

COPY ocudu-dapp-sdk /work/ocudu-dapp-sdk
RUN --mount=type=cache,id=ocudu-sdk-cuda-ccache,target=/root/.cache/ccache \
    cmake -S /work/ocudu-dapp-sdk -B /work/ocudu-dapp-sdk/build-cuda -G Ninja \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_C_COMPILER_LAUNCHER=ccache -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
      -DCMAKE_CUDA_COMPILER_LAUNCHER=ccache \
      -DCMAKE_PREFIX_PATH=/opt/ocudu \
      "-DCMAKE_CUDA_ARCHITECTURES=${OCUDU_CUDA_ARCHITECTURES}" \
      -DOCUDU_DAPP_BUILD_CUDA_EXAMPLES=ON \
      -DOCUDU_DAPP_BUILD_PYTHON_CLASS_C=OFF \
      -DOCUDU_DAPP_REF_EXTRAS=ON \
      -DOCUDU_DAPP_REQUIRE_ABI_COMPILER_MATRIX=ON \
  && cmake --build /work/ocudu-dapp-sdk/build-cuda --parallel ${OCUDU_JOBS} \
  && ctest --test-dir /work/ocudu-dapp-sdk/build-cuda --output-on-failure \
      -R '^(abi\.public_v1_compiler_matrix|docs\.release_metadata|install\.public_consumer|scaffold\.class_a_cuda_generation)$' \
  && cmake --install /work/ocudu-dapp-sdk/build-cuda --prefix /opt/ocudu

COPY --chmod=0755 ocudu-docker/scripts /work/ocudu-docker/scripts

# Which sources the image was built from (scripts/build.sh passes them from
# the workspace's sources.env or the checkouts themselves).
ARG OCUDU_PLATFORM_REVISION=unknown
ARG OCUDU_SDK_REVISION=unknown
LABEL org.opencontainers.image.title="OCUDU dApp release" \
      org.opencontainers.image.source="https://gitlab.com/ocudu/work_groups/wg2_ai_ran/ocudu-dapp-quickstart" \
      org.ocudu.platform.revision="${OCUDU_PLATFORM_REVISION}" \
      org.ocudu.sdk.revision="${OCUDU_SDK_REVISION}"

ENV OCUDU_E3_SCHEMA_DIR=/work/ocudu/schemas/e3 \
    OCUDU_E3_PYTHON_DIR=/work/ocudu/python \
    OCUDU_DAPP_SDK_BUILD=/work/ocudu-dapp-sdk/build-cuda \
    OCUDU_CERTIFY_CLASS_A_CUDA=/work/ocudu-dapp-sdk/build-cuda/certify_class_a_cuda \
    PYTHONPATH=/work/ocudu/python
WORKDIR /work
CMD ["/bin/bash"]
