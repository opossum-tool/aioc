#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

export DOCKER_BUILDKIT=1

docker build oss-review-toolkit --tag ort/with_opossum --network=host
docker build . --tag opossum/aioc --network=host
