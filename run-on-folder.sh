#!/usr/bin/env bash

# SPDX-FileCopyrightText: TNG Technology Consulting GmbH <https://www.tngtech.com>
#
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

if [[ "$1" == "--build" ]]; then
    shift
    "$(dirname "$0")"/build-docker-image.sh
fi

input="$(readlink -f "$1")"
output="$(readlink -f "${2:-${input}_aioc}")"
mkdir -p "$output"
trap "sudo chown '$(id -u):$(id -g)' -R '$output'" EXIT

docker run -v "$input":/input:ro -v "$output":/output opossum/aioc
