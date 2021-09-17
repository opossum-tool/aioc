#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

export DOCKER_BUILDKIT=1

git submodule init
git submodule update --remote

docker build oss-review-toolkit --tag ort/with_opossum --network=host
docker build . --tag opossum/aioc --network=host
