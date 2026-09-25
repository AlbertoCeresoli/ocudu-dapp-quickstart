#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (C) 2026 DeepSig Inc.
# SPDX-License-Identifier: BSD-3-Clause-Clear
#
# Fetch the public OCUDU dApp platform and SDK next to this repository, the
# layout the images build from:
#
#   <workspace>/ocudu            ocudu-dapp-platform (the gNB, dApp runtime, E3)
#   <workspace>/ocudu-dapp-sdk   ocudu-dapp-sdk
#   <workspace>/ocudu-docker     this repository
#
#   ocudu-docker/scripts/fetch_sources.sh                  # main of both, into the parent of ocudu-docker
#   ocudu-docker/scripts/fetch_sources.sh /path/to/workspace
#   OCUDU_PLATFORM_REF=<sha> OCUDU_SDK_REF=<sha> ocudu-docker/scripts/fetch_sources.sh --update
#
# Missing repositories are cloned at the requested refs (default main). An
# existing checkout is left exactly as it is — your branch, your changes — unless
# --update is given, which fetches and checks out the requested ref (detached)
# and refuses when the checkout has local changes. The resolved commits are
# written to <workspace>/sources.env, which build.sh records in the image labels.
set -euo pipefail

here="$(cd "$(dirname "$0")/.." && pwd)"
update=false
positional=()
for argument in "$@"; do
  case "${argument}" in
    --update) update=true ;;
    -h|--help) sed -n '4,20p' "$0"; exit 0 ;;
    *) positional+=("${argument}") ;;
  esac
done
root="${positional[0]:-$(dirname "${here}")}"
platform_url="${OCUDU_PLATFORM_URL:-https://gitlab.com/ocudu/work_groups/wg2_ai_ran/ocudu-dapp-platform.git}"
platform_ref="${OCUDU_PLATFORM_REF:-main}"
sdk_url="${OCUDU_SDK_URL:-https://gitlab.com/ocudu/work_groups/wg2_ai_ran/ocudu-dapp-sdk.git}"
sdk_ref="${OCUDU_SDK_REF:-main}"

# fetch <url> <ref> <directory>
fetch() {
  local url="$1" ref="$2" directory="$3"
  if [[ -d "${directory}/.git" || -f "${directory}/.git" ]]; then
    if [[ "${update}" != true ]]; then
      echo "${directory}: kept as is ($(git -C "${directory}" log -1 --format='%h %cs %s'))"
      return 0
    fi
    if [[ -n "$(git -C "${directory}" status --porcelain --untracked-files=no)" ]]; then
      echo "${directory} has local changes; not updating it" >&2
      exit 1
    fi
    git -C "${directory}" fetch --quiet "${url}" "${ref}"
    git -C "${directory}" checkout --quiet --detach FETCH_HEAD
  else
    git clone --quiet --no-checkout "${url}" "${directory}"
    git -C "${directory}" fetch --quiet origin "${ref}"
    git -C "${directory}" checkout --quiet --detach FETCH_HEAD
  fi
  git -C "${directory}" submodule update --quiet --init --recursive
  echo "${directory}: $(git -C "${directory}" log -1 --format='%h %cs %s')"
}

mkdir -p "${root}"
fetch "${platform_url}" "${platform_ref}" "${root}/ocudu"
fetch "${sdk_url}" "${sdk_ref}" "${root}/ocudu-dapp-sdk"
if [[ "$(cd "${here}/.." && pwd)" != "$(cd "${root}" && pwd)" && ! -e "${root}/ocudu-docker" ]]; then
  # A workspace elsewhere gets a copy of this repository's tracked files.
  mkdir -p "${root}/ocudu-docker"
  git -C "${here}" archive HEAD | tar -x -C "${root}/ocudu-docker"
fi

cat > "${root}/sources.env" <<EOF
OCUDU_PLATFORM_URL=${platform_url}
OCUDU_PLATFORM_REVISION=$(git -C "${root}/ocudu" rev-parse HEAD)
OCUDU_SDK_URL=${sdk_url}
OCUDU_SDK_REVISION=$(git -C "${root}/ocudu-dapp-sdk" rev-parse HEAD)
EOF
echo "sources recorded in ${root}/sources.env"
