#!/usr/bin/env bash

# SPDX-FileCopyrightText: TNG Technology Consulting GmbH <https://www.tngtech.com>
#
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

cd "$(dirname "$0")"

export DOCKER_BUILDKIT=1

git submodule init
git submodule update --remote

docker build oss-review-toolkit --tag ort/with_opossum --network=host
docker build . -f aioc/Dockerfile --tag opossum/aioc --network=host
