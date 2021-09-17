#!/usr/bin/env bash
set -euo pipefail

input="$(readlink -f "$1")"
output="${input}_aioc"
mkdir -p "$output"
trap "sudo chown '$(id -u):$(id -g)' -R '$output'" EXIT

docker run -v "$input":/input -v "$output":/output opossum/aioc
