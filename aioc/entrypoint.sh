#!/usr/bin/env bash
set -euo pipefail

runExtractcode() (
    local input="$(readlink -f "$1")"
    cd "$(dirname "$(readlink -f "$(which scancode)")")"
    ./extractcode "$input"
)

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
        --strip-root || [[ -f "$output" ]]
}

runORT() {
    local input="$1"
    local output="$2"

    local scanResult="$output/scan-result.yml"
    if [[ ! -f "$scanResult" ]]; then
        local analyzerResult="$output/analyzer-result.yml"
        if [[ ! -f "$analyzerResult" ]]; then
            ort --force-overwrite --performance \
                -P ort.analyzer.allowDynamicVersions=true analyze --output-formats YAML \
                -i "$input" \
                -o "$output" || [[ -f "$analyzerResult" ]]
        fi

        ort --force-overwrite --performance \
            scan --output-formats YAML -s "Scancode" \
            -i "$analyzerResult" \
            -o "$output" || true
    fi

    if [[ -f "$scanResult" ]]; then
        ort --force-overwrite --performance \
            report -f Opossum \
            -i "$scanResult" \
            -o "$output"
    else
        ort --force-overwrite --performance \
            report -f Opossum \
            -i "$analyzerResult" \
            -o "$output"
    fi
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

runOwaspDependencyCheck() (
    local input="$(readlink -f "$1")"
    local output="$(readlink -f "$2")"
    local outputfile="$output/dependency-check-report.json"
    cd "$input"
    dependency-check.sh \
     --format JSON \
     --data /dependency-check-data \
     --log "$output/log" \
     --out "$output" \
     --scan "."

    local tmpfile="$(mktemp)"
    jq . "$outputfile" | sed 's%"'"$input"'/%"%g' > "$tmpfile"
    mv "$tmpfile" "$outputfile"
)

main() {
    local input="$1"
    local output="$2"

    local inputExtracted="$output/input"
    if [[ ! -d "$inputExtracted" ]]; then
        cp -r "$input" "$inputExtracted"
        runExtractcode "$inputExtracted"
    fi

    [[ -f "$output/scancode/scancode.json" ]] || runScancode "$inputExtracted" "$output/scancode/scancode.json"
    [[ -f "$output/ort/opossum.input.json.gz" ]] || runORT "$inputExtracted" "$output/ort"
    [[ -f "$output/SCANOSS/scanoss.json.opossum.json" ]] || runSCANOSS "$inputExtracted" "$output/SCANOSS"
    [[ -f "$output/owaspDependencyCheck/dependency-check-report.json" ]] || runOwaspDependencyCheck "$inputExtracted" "$output/owaspDependencyCheck"

    opossum.lib.hs \
        "$output/ort/opossum.input.json.gz" \
        --scancode "$output/scancode/scancode.json" \
        "$output/SCANOSS/scanoss.json.opossum.json" \
        --dependency-check "$output/owaspDependencyCheck/dependency-check-report.json" \
        > "$output/merged-opossum.input.json"

    gzip -f "$output/merged-opossum.input.json"
}

[[ -f ~/.ssh/id_rsa ]] || ssh-keygen -b 2048 -t rsa -f ~/.ssh/id_rsa -q -N ""

main "${1:-/input}" "${2:-/output}"
