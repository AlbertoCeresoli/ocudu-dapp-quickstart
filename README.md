<!-- SPDX-FileCopyrightText: Copyright (C) 2026 DeepSig Inc. -->
<!-- SPDX-License-Identifier: BSD-3-Clause-Clear -->

# OCUDU AI-RAN dApp/E3 quickstart

**Canonical home:** <https://gitlab.com/ocudu/work_groups/wg2_ai_ran/ocudu-dapp-quickstart>

Everything you need to start building and operating AI-RAN dApps on OCUDU:
one command builds the whole public release set into validated container
images, a loopback E3 agent lets you run every tutorial with **no radio, no
GPU, no keys**, and this page indexes the complete documentation across the
three repositories.

| Repository | What it is |
|---|---|
| [ocudu-dapp-platform](https://gitlab.com/ocudu/work_groups/wg2_ai_ran/ocudu-dapp-platform) | the OCUDU gNB with the dApp runtime and embedded E3 management/telemetry plane |
| [ocudu-dapp-sdk](https://gitlab.com/ocudu/work_groups/wg2_ai_ran/ocudu-dapp-sdk) | the standalone dApp authoring toolkit: reference packages, scaffolds, validation ladder, examples |
| this repo | the reproducible container build, the zero-hardware E3 testbed, and this quickstart index |

Clone the set side by side. The directory names are part of the contract —
the Dockerfile `COPY`s and every cross-repo documentation link use them:

```bash
# clone the set side by side; the platform repo must be cloned as ocudu/
mkdir ocudu-workspace && cd ocudu-workspace
git clone https://gitlab.com/ocudu/work_groups/wg2_ai_ran/ocudu-dapp-platform.git ocudu
git clone https://gitlab.com/ocudu/work_groups/wg2_ai_ran/ocudu-dapp-sdk.git
git clone https://gitlab.com/ocudu/work_groups/wg2_ai_ran/ocudu-dapp-quickstart.git ocudu-docker
```

## Read first: the two papers (preview versions)

Two papers explain the motivation, architecture, measurements, and workflow
behind everything in this quickstart. Both are preview versions that
accompany this pre-release and will receive updates as the working group's
review, new use cases, and measurements land.

| Paper | What it gives you |
|---|---|
| [**The OCUDU dApp Platform: An Open Runtime and E3 Interface for Real-Time AI-RAN**](papers/ocudu_dapp_tutorial.pdf) | the architecture and tutorial paper: the 3 execution classes, the E3 plane, where every mechanism lives in the code, how to build, sign, load, and drive a dApp, the 7 use cases, the safety and latency design, and the measured evidence |
| [**Enabling AI-RAN Applications Through dApp Architecture Decisions: A Measured Study**](papers/ocudu_dapp_interface_study.pdf) | the interface study: an audited corpus of 39 AI-RAN use cases with deadlines and byte counts, the coupling spectrum from an in-process C ABI to E3AP over SCTP, measurements of the real mechanisms used by the OCUDU, Northeastern, and NVIDIA dApp frameworks on a quiet host and with the cell on the air, and the derivation of the released ABI |

## Start here — the guided path

Fastest working session: clone (above), `ocudu-docker/scripts/build.sh`, then
[Tutorial 0 — the zero-hardware testbed](https://gitlab.com/ocudu/work_groups/wg2_ai_ran/ocudu-dapp-platform/-/blob/main/docs/dapp/tutorial_docker_testbed.md)
brings up the loopback E3 agent and points every later tutorial command at it.

The full tutorial ladder, from an empty vendor repo to an LLM agent tuning a
live cell (1–4 need no keys):

| # | Tutorial | You will… |
|---|----------|-----------|
| 0 | [The zero-hardware testbed](https://gitlab.com/ocudu/work_groups/wg2_ai_ran/ocudu-dapp-platform/-/blob/main/docs/dapp/tutorial_docker_testbed.md) | build these images and run everything radio-free |
| 1 | [Stand up a new vendor dApp repo](https://gitlab.com/ocudu/work_groups/wg2_ai_ran/ocudu-dapp-sdk/-/blob/main/docs/tutorial_new_vendor_repo.md) | scaffold → build → certify against the installed SDK |
| 2 | [Install & load dApps from the gNB YAML](https://gitlab.com/ocudu/work_groups/wg2_ai_ran/ocudu-dapp-platform/-/blob/main/docs/dapp/tutorial_install_and_yaml.md) | catalog, trust policy, instances at startup or over E3 |
| 3 | [Operate dApps with `dappctl`](https://gitlab.com/ocudu/work_groups/wg2_ai_ran/ocudu-dapp-platform/-/blob/main/docs/dapp/tutorial_dappctl_operations.md) | lifecycle, A/B version swap, circuit breakers |
| 4 | [Monitor & tune over the MCP server](https://gitlab.com/ocudu/work_groups/wg2_ai_ran/ocudu-dapp-sdk/-/blob/main/docs/tutorial_mcp_monitoring.md) | ask the gNB questions; KPI-driven LLM tuning loops |
| 5 | [Signing, SBOMs & key management](https://gitlab.com/ocudu/work_groups/wg2_ai_ran/ocudu-dapp-platform/-/blob/main/docs/dapp/tutorial_signing_and_trust.md) | the production trust path |
| 6 | [Exposing dApp KPIs over E3](https://gitlab.com/ocudu/work_groups/wg2_ai_ran/ocudu-dapp-platform/-/blob/main/docs/dapp/tutorial_dapp_kpis.md) | declare metrics; read them from any client |
| 7 | [Your first dApp: standalone Class-C](https://gitlab.com/ocudu/work_groups/wg2_ai_ran/ocudu-dapp-platform/-/blob/main/docs/dapp/tutorial_class_c_standalone.md) | a Python out-of-process dApp against this testbed |
| 8 | [Telemetry deep-dive & data capture](https://gitlab.com/ocudu/work_groups/wg2_ai_ran/ocudu-dapp-platform/-/blob/main/docs/dapp/tutorial_telemetry_capture.md) | all 8 streams, HDF5 capture, offline PUSCH replay |
| 9 | [Neural-model operations](https://gitlab.com/ocudu/work_groups/wg2_ai_ran/ocudu-dapp-platform/-/blob/main/docs/dapp/tutorial_model_operations.md) | stage → validate → warm → activate → rollback |
| 10 | [Class-B scheduler control](https://gitlab.com/ocudu/work_groups/wg2_ai_ran/ocudu-dapp-platform/-/blob/main/docs/dapp/tutorial_class_b_scheduler.md) | the ~100 µs contract, sensing→avoidance |
| 11 | [Troubleshooting runbook](https://gitlab.com/ocudu/work_groups/wg2_ai_ran/ocudu-dapp-platform/-/blob/main/docs/dapp/tutorial_troubleshooting.md) | symptom → cause → fix |
| 12 | [Capstone: the whole loop](https://gitlab.com/ocudu/work_groups/wg2_ai_ran/ocudu-dapp-platform/-/blob/main/docs/dapp/tutorial_capstone.md) | capture → train → package → shadow → activate → monitor → rollback |

## Documentation map

**Papers (preview)** — [architecture and tutorial paper](papers/ocudu_dapp_tutorial.pdf) · [interface study](papers/ocudu_dapp_interface_study.pdf)

**Platform (gNB, runtime, E3)** — [docs index](https://gitlab.com/ocudu/work_groups/wg2_ai_ran/ocudu-dapp-platform/-/blob/main/docs/dapp/README.md):
[quickstart](https://gitlab.com/ocudu/work_groups/wg2_ai_ran/ocudu-dapp-platform/-/blob/main/docs/dapp/quickstart.md) ·
[capabilities reference](https://gitlab.com/ocudu/work_groups/wg2_ai_ran/ocudu-dapp-platform/-/blob/main/docs/dapp/capabilities.md) ·
[operations cookbook](https://gitlab.com/ocudu/work_groups/wg2_ai_ran/ocudu-dapp-platform/-/blob/main/docs/dapp/operations_cookbook.md) ·
[extension model](https://gitlab.com/ocudu/work_groups/wg2_ai_ran/ocudu-dapp-platform/-/blob/main/docs/dapp/extension_model.md) ·
[YAML configuration](https://gitlab.com/ocudu/work_groups/wg2_ai_ran/ocudu-dapp-platform/-/blob/main/docs/dapp/yaml_configuration.md) ·
[E3 management](https://gitlab.com/ocudu/work_groups/wg2_ai_ran/ocudu-dapp-platform/-/blob/main/docs/dapp/e3_management.md) ·
[E3 wire formats](https://gitlab.com/ocudu/work_groups/wg2_ai_ran/ocudu-dapp-platform/-/blob/main/docs/dapp/e3_wire.md) ·
[system design](https://gitlab.com/ocudu/work_groups/wg2_ai_ran/ocudu-dapp-platform/-/blob/main/docs/dapp/e3_system_design.md) ·
[security model](https://gitlab.com/ocudu/work_groups/wg2_ai_ran/ocudu-dapp-platform/-/blob/main/docs/dapp/security_model.md) ·
[API compatibility](https://gitlab.com/ocudu/work_groups/wg2_ai_ran/ocudu-dapp-platform/-/blob/main/docs/dapp/api_compatibility.md) ·
[release checklist](https://gitlab.com/ocudu/work_groups/wg2_ai_ran/ocudu-dapp-platform/-/blob/main/docs/dapp/release_checklist.md) ·
[known limitations](https://gitlab.com/ocudu/work_groups/wg2_ai_ran/ocudu-dapp-platform/-/blob/main/docs/dapp/known_limitations.md) ·
[glossary](https://gitlab.com/ocudu/work_groups/wg2_ai_ran/ocudu-dapp-platform/-/blob/main/docs/dapp/glossary.md) ·
[proposing extensions](https://gitlab.com/ocudu/work_groups/wg2_ai_ran/ocudu-dapp-platform/-/blob/main/docs/dapp/proposing_extensions.md)

**SDK (authoring dApps)** — [docs index](https://gitlab.com/ocudu/work_groups/wg2_ai_ran/ocudu-dapp-sdk/-/blob/main/docs/README.md) ·
[getting started ladder](https://gitlab.com/ocudu/work_groups/wg2_ai_ran/ocudu-dapp-sdk/-/blob/main/README.md):
[SDK quickstart](https://gitlab.com/ocudu/work_groups/wg2_ai_ran/ocudu-dapp-sdk/-/blob/main/docs/ocudu_dapp_quickstart.md) ·
[vendor toolkit](https://gitlab.com/ocudu/work_groups/wg2_ai_ran/ocudu-dapp-sdk/-/blob/main/docs/vendor_toolkit.md) ·
[Class-A CUDA authoring](https://gitlab.com/ocudu/work_groups/wg2_ai_ran/ocudu-dapp-sdk/-/blob/main/docs/class_a_cuda_authoring.md) ·
[Class-B accelerator authoring](https://gitlab.com/ocudu/work_groups/wg2_ai_ran/ocudu-dapp-sdk/-/blob/main/docs/class_b_accelerator_authoring.md) ·
[Class-B scheduler baseline](https://gitlab.com/ocudu/work_groups/wg2_ai_ran/ocudu-dapp-sdk/-/blob/main/docs/class_b_scheduler_baseline.md) ·
[Class-C process authoring](https://gitlab.com/ocudu/work_groups/wg2_ai_ran/ocudu-dapp-sdk/-/blob/main/docs/class_c_cuda_process_authoring.md) ·
[reference packages](https://gitlab.com/ocudu/work_groups/wg2_ai_ran/ocudu-dapp-sdk/-/blob/main/docs/reference_packages.md) ·
[package config](https://gitlab.com/ocudu/work_groups/wg2_ai_ran/ocudu-dapp-sdk/-/blob/main/docs/package_config.md) ·
[validation ladder](https://gitlab.com/ocudu/work_groups/wg2_ai_ran/ocudu-dapp-sdk/-/blob/main/docs/validation_ladder.md) ·
[tools](https://gitlab.com/ocudu/work_groups/wg2_ai_ran/ocudu-dapp-sdk/-/blob/main/docs/tools.md) ·
[run the examples](https://gitlab.com/ocudu/work_groups/wg2_ai_ran/ocudu-dapp-sdk/-/blob/main/docs/run_examples.md) ·
[MCP companion](https://gitlab.com/ocudu/work_groups/wg2_ai_ran/ocudu-dapp-sdk/-/blob/main/docs/mcp_companion.md) ·
[observer authority](https://gitlab.com/ocudu/work_groups/wg2_ai_ran/ocudu-dapp-sdk/-/blob/main/docs/observer_authority.md) ·
[extension model](https://gitlab.com/ocudu/work_groups/wg2_ai_ran/ocudu-dapp-sdk/-/blob/main/docs/extension_model.md) ·
[security model](https://gitlab.com/ocudu/work_groups/wg2_ai_ran/ocudu-dapp-sdk/-/blob/main/docs/security_model.md) ·
[compatibility](https://gitlab.com/ocudu/work_groups/wg2_ai_ran/ocudu-dapp-sdk/-/blob/main/docs/compatibility.md) ·
[known limitations](https://gitlab.com/ocudu/work_groups/wg2_ai_ran/ocudu-dapp-sdk/-/blob/main/docs/known_limitations.md) ·
[releasing](https://gitlab.com/ocudu/work_groups/wg2_ai_ran/ocudu-dapp-sdk/-/blob/main/docs/releasing.md)

**Runnable examples (SDK)**:
[vendor_min — copy-me commercial Class-A](https://gitlab.com/ocudu/work_groups/wg2_ai_ran/ocudu-dapp-sdk/-/blob/main/examples/vendor_min/README.md) ·
[Python E3 telemetry observers](https://gitlab.com/ocudu/work_groups/wg2_ai_ran/ocudu-dapp-sdk/-/blob/main/examples/e3_telemetry_python/README.md) ·
[spectrum sensing over E3](https://gitlab.com/ocudu/work_groups/wg2_ai_ran/ocudu-dapp-sdk/-/blob/main/examples/e3_spectrum_sensing/README.md) ·
[SRS-ISAC starting point](https://gitlab.com/ocudu/work_groups/wg2_ai_ran/ocudu-dapp-sdk/-/blob/main/examples/e3_isac_sensing/README.md) ·
[Python Class-C sensing](https://gitlab.com/ocudu/work_groups/wg2_ai_ran/ocudu-dapp-sdk/-/blob/main/examples/class_c_e3_python/README.md) ·
[MCP server](https://gitlab.com/ocudu/work_groups/wg2_ai_ran/ocudu-dapp-sdk/-/blob/main/examples/e3_mcp_server/README.md)

## The images

One Dockerfile builds the two public release repositories from their current
workspace contents without using host build trees:

- `ocudu`: host dApp runtime, E3 management/telemetry, tools, and gNB;
- `ocudu-dapp-sdk`: CPU and CUDA reference packages plus public examples.

The CPU target is portable. The CUDA target compiles the CUDA SDK in a CUDA 13
development image, while runtime GPU tests remain a separate, explicit
`--gpus all` gate. Vendor-internal package catalogs layer their own image on
top of these targets from a separate overlay repository; nothing private
enters this build context.

| Stage | What it builds | Gates it runs |
|-------|----------------|---------------|
| `toolchain` | compilers, `asn1c` (mouse07410 fork, pinned, APER generator), `flatc`, Python venv with `asn1tools` | — |
| `ocudu-host` | OCUDU with `ENABLE_DAPP/ENABLE_E3/ENABLE_E3_ASN1_CODEC` (CPU) and radio support (`ENABLE_UHD`, split-7.2 OFH, `ENABLE_DPDK`), `gnb`, `ocudu-dappctl`, preflight and packaging tools, `dapp_runtime_test`, the loopback E3 agent; installs the `dapp_sdk` component to `/opt/ocudu` | `dapp_runtime_test` (runtime, E3 codecs, SCTP carriers), Python E3AP cross-language test, release-docs check |
| `dapp-sdk` | standalone CPU `ocudu-dapp-sdk` against `/opt/ocudu` (reference packages, ABI matrix, install consumer) | full CPU SDK `ctest` |
| `cpu-release` | the portable image: the two stages above plus scripts and environment | — |
| `cuda-toolchain` | multi-architecture CUDA 13 compiler/runtime development environment | device-free toolchain checks |
| `cuda-release` | CUDA-accelerated gNB host (`ENABLE_CUDA`, radio support included) plus the CUDA reference SDK (every reference package, manifest, SBOM, certifier) | ABI/install/docs gates during image construction |

The default CUDA architecture set is `89-real;90-real;121`: RTX 4090, GH200,
and GB10. Override `OCUDU_CUDA_ARCHITECTURES` for a narrower deployment image.

## Build

```bash
cd /path/to/workspace   # holds ocudu/ and ocudu-dapp-sdk/ side by side
# Builds ocudu-dapp-release:cpu-local and ocudu-dapp-release:cuda-local.
ocudu-docker/scripts/build.sh

# Build only one product when iterating.
OCUDU_BUILD_VARIANT=cpu  ocudu-docker/scripts/build.sh
OCUDU_BUILD_VARIANT=cuda ocudu-docker/scripts/build.sh

# Equivalent Compose build of both release targets.
docker compose -f ocudu-docker/docker-compose.yml build release release-cuda
```

Useful arguments: `OCUDU_JOBS` (parallelism, default 8), `OCUDU_BUILD_TYPE`
(`Release` default), `OCUDU_CUDA_ARCHITECTURES`, `OCUDU_CUDA_IMAGE`, and
`OCUDU_DOCKER_CPUSET`. `ASN1C_COMMIT` is a Dockerfile argument pinned to the
release's APER-capable `asn1c` fork.

## Run the gates again or explore

```bash
docker compose -f ocudu-docker/docker-compose.yml run --rm tests
docker compose -f ocudu-docker/docker-compose.yml run --rm cuda-tests

docker run --rm -it ocudu-dapp-release:cpu-local
docker run --rm --gpus all -it ocudu-dapp-release:cuda-local
#   /work/ocudu/build/apps/gnb/gnb --help
#   python3 -m ocudu_e3 --help
```

## Try the E3 interface without a radio

This is the recommended companion for the step-by-step tutorials in
`ocudu/docs/dapp/` and `ocudu-dapp-sdk/docs/`: every E3 command they show can
be pointed at this loopback testbed instead of a live cell.

`docker compose -f ocudu-docker/docker-compose.yml up e3-agent` starts the loopback E3 agent (synthetic PUSCH
symbols/CRC, SRS, gNB JSON) on E3AP `sctp/36423` and the FlatBuffers data
profile on `sctp/38472`. From the host:

```bash
export PYTHONPATH=ocudu/python
export OCUDU_E3_SCHEMA_DIR=ocudu/schemas/e3
python3 -m ocudu_e3 --port 36423 catalog
python3 -m ocudu_e3 --port 36423 subscribe pusch.symbols pusch.crc --maximum 5
python3 ocudu/apps/tools/dappctl/ocudu_dappctl.py --sctp 127.0.0.1:36423 inventory
```

SCTP must be available on the Docker host kernel (`modprobe sctp`); Docker
publishes SCTP ports with the `/sctp` suffix used in `docker-compose.yml`.

## Run with a radio

Radio support is built into every image: the UHD driver for split-8 USRPs
(B200/B210/N310), split-7.2 Open Fronthaul on the kernel raw-socket
transport, and the DPDK fronthaul backend. No rebuild is needed — the example
gNB services below run the standard `ocudu-dapp-release:cpu-local` image
(swap in `cuda-local` for the CUDA-accelerated L1).

### Split 8 — USRP (B200/B210/N310)

```bash
docker compose -f ocudu-docker/docker-compose.yml --profile radio up gnb-usrp
```

The `gnb-usrp` service runs `examples/gnb_b210_split8_dapp.yml` (TDD n78,
20 MHz, the dApp platform enabled in no-keys lab posture) with the host USB
bus passed through, host networking, `SYS_NICE`, and unlimited memlock.
Host prep: the USRP on USB3, `uhd_find_devices` sees it, no other process
owns it. First run inside the image may need `uhd_images_downloader`.

### Split 7.2 — O-RU over Open Fronthaul (WNC-class and similar)

```bash
docker compose -f ocudu-docker/docker-compose.yml --profile radio up gnb-oru
```

The `gnb-oru` service runs `examples/gnb_oru_split72_dapp.yml`. The shipped
timing/compression values are the platform's Picocom SCB example; for a WNC,
Benetel, or other O-RU substitute that RU's integration values (t1a/ta4
windows, compression, VLAN tags, MAC/port maps) — the structure is identical,
and the platform ships further O-RU examples under `ocudu/configs/gnb_ru_*`.
Host prep is the usual fronthaul checklist and stays on the host: PTP/SyncE
(`ptp4l` + `phc2sys` against the RU's grandmaster), the fronthaul NIC up with
the VLANs configured, and the RU reachable at L2. The service uses host
networking with `NET_RAW`/`NET_ADMIN` so the containerized DU opens the raw
socket directly. The DPDK fronthaul backend is compiled in (Ubuntu 24.04's
`libdpdk` 23.11 meets the >= 22.11 floor); enabling it is a runtime choice in
the gNB YAML and needs hugepages + NIC binding prepared on the host.

Containerized real-time caveat, stated plainly: these services set rtprio and
memlock and pin nothing else. For qualification-grade timing use the same
binaries on the bare host (or add cpuset pinning and isolated cores to the
service) — the container is for bring-up and development convenience.

## Platform matrix

Built and exercised DGX-Spark-first (GB10, arm64); the same Dockerfile serves
the rest of the range:

| Host | CPU image | CUDA image (`OCUDU_CUDA_ARCHITECTURES`) |
|---|---|---|
| NVIDIA DGX Spark (GB10) | yes (arm64) | `121` |
| NVIDIA GH200 | yes (arm64) | `90-real` |
| x86 server + RTX 6000 Ada / similar | yes (amd64) | `89-real` (set to your GPU) |
| Intel / AMD / ARM server, no GPU | yes | — (CPU L1 + CPU reference dApps) |

The base images are multi-arch (Ubuntu 24.04, CUDA 13 devel); pick the CUDA
architecture list for your deployment GPU, or skip the CUDA target entirely
for a CPU-only platform — every Class-B/C reference and the whole E3/tutorial
flow run on the CPU image.

## What this image is not

- Not a site qualification: the images carry the radio drivers (UHD,
  split-7.2 OFH, DPDK) and the CUDA image a CUDA-accelerated gNB, but
  production timing, pinning, and RU integration values remain per-site work
  (see the real-time caveat above).
- Not a substitute for the OTA gates in `docs/dapp/release_checklist.md`.
- Not the home of vendor-internal catalogs or operations dashboards; those
  build in their own overlay image on top of `cpu-release`/`cuda-release`.

The build context is the workspace root; the tracked
`Dockerfile.dockerignore` excludes host `build*/` trees, `.git`, and caches so
a stale host CMake cache can never leak into the image. A public checkout needs only `ocudu/` and `ocudu-dapp-sdk/`;
if other sibling repos happen to sit in the workspace they are uploaded with
the context but only the COPY'd public paths ever enter an image layer.

(`OCUDU_CUDA_IMAGE` is the `build.sh`/compose environment variable; it feeds
the Dockerfile's `CUDA_IMAGE` ARG. `OCUDU_C_COMPILER`/`OCUDU_CXX_COMPILER`
default to clang/clang++. Set `OCUDU_DOCKER_CPUSET` when a live gNB shares the
host.)

One unit test is excluded inside the container:
`requires_seccomp_filter_before_route_admission_when_configured` asserts that a
Class-C worker *without* a seccomp filter is rejected, but the Docker runtime
already applies a seccomp filter to every process (`Seccomp: 2` in
`/proc/<pid>/status`), so the negative case cannot be exercised there. Run it
on a bare host (`ctest -R dapp_runtime`) where it passes.
