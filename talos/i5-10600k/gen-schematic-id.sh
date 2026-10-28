#!/bin/bash
set -euo pipefail

NODE_NAME=$1

curl -s https://factory.talos.dev/schematics \
    --header 'Content-Type: application/json' \
    --data '
    customization:
        extraKernelArgs:
            - talos.hostname='${NODE_NAME}'
        systemExtensions:
            officialExtensions:
                - siderolabs/i915
                - siderolabs/intel-ucode
                - siderolabs/zfs
    ' | jq --raw-output '.id'
