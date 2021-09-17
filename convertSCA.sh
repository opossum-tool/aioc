#!/usr/bin/env bash

# SPDX-FileCopyrightText: Facebook, Inc. and its affiliates
# SPDX-FileCopyrightText: TNG Technology Consulting GmbH <https://www.tngtech.com>
#
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

if [[ $# -lt 2 ]]; then
    cat <<EOF
Usage:

    $0 SCA_FILE OPOSSUM_FILE_TO_AUGMENT

this script
  1) parses the scanoss json result SCA_FILE,
  2) uses the providde OPOSSUM_FILE_TO_AUGMENT as a baseline and
  3) generates a new input file placed at "${SCA_FILE}.opossum.json" that contains all data

NOTE:
* all files already need to be existent in the initial opossum that is to be augmented
* this script is rather hacky and not optimized for performance: it parses the same file multiple times with jq
EOF
    exit 1
fi

migrateSCAtoOPOSSUM() {
  sca="$1"
  opossum="$2"
  if [[ ! -f "$opossum" ]]; then
    echo "valid opossum file has to exist, not found '$opossum'"
    exit 1
  fi

  out="${sca}.opossum.json"
  if [[ ! -f "$out" ]]; then
    outPre="${sca}.opossum.pre.json"
    if [[ ! -f "$outPre" ]]; then
      i=0
      externalAttributions="${sca}.externalAttributions"
      resourcesToAttributions="${sca}.resourcesToAttributions"

      if [[ ! -f $externalAttributions && ! -f $resourcesToAttributions ]]; then
        declare -a attUUIDs
        for entry in $(cat "$sca" | jq -r '. | to_entries | .[] | @base64'); do
          entry=$(echo ${entry} | base64 --decode)
          file=$(echo $entry | jq -r '.key')
          values=$(echo $entry | jq -r '.value')
          attUUIDs=()

          if [[ "$values" != "null" ]]; then
            for value in $(echo $values | jq -r '. | .[] | @base64'); do
              value=$(echo ${value} | base64 --decode)
              if [[ "$(echo $value | jq -r '.id')" !=  none ]]; then
                if [[ "$value" != "null" ]]; then
                  echo i: $i
                  ((i=i+1))
                  uuid=$(uuidgen)
                  comment="$(echo "$value" | jq -r '.' |  tr '\n' ';' | sed 's/;/\\n/g' | sed 's/"/\\"/g')"
                  copyrights="$(echo "$value" | jq -r '.copyrights | .[].name' | tr '\n' ';' | sed 's/;/\\n/g')"
                  licenses="$(echo "$value" | jq -r '.licenses | .[].name' | tr '\n' ';' | sed 's/;/ AND /g' | sed 's/ AND $//')"
                  cat <<EOF >> $externalAttributions
  "${uuid}": {
    "comment": "$(echo "$value" | jq -r '.url')\\n\\n${comment}",
    "packageName": "$(echo "$value" | jq -r '.vendor')/$(echo "$value" | jq -r '.component')",
    "packageVersion": "$(echo "$value" | jq -r '.version')",
    "licenseName": "${licenses}",
    "licenseText": "",
    "copyright": "${copyrights}",
    "source": {
      "documentConfidence": 0,
      "name": "SCANOSS"
    }
  },
EOF
                  attUUIDs+=("\"${uuid}\"")
                fi
              fi
            done
          fi
          if [[ "${#attUUIDs[@]}" -gt 0 ]]; then
          joined=""
          printf -v joined '%s,' "${attUUIDs[@]}"
          cat <<EOF | tee -a "$resourcesToAttributions"
  "$(echo "$file" | sed 's%^\./\?%/%' | sed 's%^/\?%/%')": [${joined%,}],
EOF
          fi
        done
      fi

      truncate -s-2 $externalAttributions
      truncate -s-2 $resourcesToAttributions

      cat <<EOF > $outPre
  {
    "externalAttributions": {
      $(cat $externalAttributions)
    },
  "resourcesToAttributions": {
      $(cat $resourcesToAttributions)
    }
  }
EOF
      rm -f $externalAttributions $resourcesToAttributions
    fi

    jq -s 'def flatten: reduce .[] as $i([]; if $i | type == "array" then . + ($i | flatten) else . + [$i] end);
      [.[] | to_entries] | flatten | reduce .[] as $dot ({}; .[$dot.key] += $dot.value)' "$opossum" "$outPre" > "$out"
  fi
}

migrateSCAtoOPOSSUM "$1" "$2"
