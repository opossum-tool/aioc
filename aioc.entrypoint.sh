#!/usr/bin/env bash
set -euo pipefail

runScancode() {
    local input="$1"
    local output="$2"
    mkdir -p "$(dirname "$output")"

    scancode \
        -n "$(($(nproc) - 2))" \
        --license --copyright --package --info \
        "$input" \
        --license-text --license-text-diagnostics \
        --json "$output" \
        --strip-root || [ -f "$output" ]
}

runORT() {
    local input="$1"
    local output="$2"

    local analyzerResult="$output/analyzer-result.yml"
    /opt/ort/bin/ort --force-overwrite --performance \
        -P ort.analyzer.allowDynamicVersions=true analyze --output-formats YAML \
        -i "$input" \
        -o "$output" || [ -f "$analyzerResult" ]

    local scanResult="$output/scan-result.yml"
    /opt/ort/bin/ort --force-overwrite --performance \
        scan --output-formats YAML -s "Scancode" \
        -i "$analyzerResult" \
        -o "$output" || [ -f "$scanResult" ]

    /opt/ort/bin/ort --force-overwrite --performance \
        report -f Opossum \
        -i "$scanResult" \
        -o "$output"
}

runSCANOSS() (
    local input="$1"
    local scanossDir="$2"
    mkdir -p "$scanossDir"
    local scanossFile="$scanossDir/scanoss.json"
    cd "$input"
    scanner -o"$scanossFile" .

    local baseOpossum="$scanossDir/opossum-from-filetree.json"
    opossum.lib.hs "$input" > "$baseOpossum"
    convertSCA.sh "$scanossFile" "$baseOpossum"
)

runScancode "/input" "/output/scancode/scancode.json"
runORT "/input" "/output/ort"
runSCANOSS "/input" "/output/SCANOSS"

opossum.lib.hs \
    "/output/ort/opossum.input.json.gz" \
    --scancode "/output/scancode/scancode.json" \
    "/output/SCANOSS/scanoss.json.opossum.json" \
    > /output/merged-opossum.input.json

gzip /output/merged-opossum.input.json
