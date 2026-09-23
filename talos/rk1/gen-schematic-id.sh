#!/bin/bash
set -euo pipefail

HOSTNAME=$1

curl -s https://factory.talos.dev/schematics \
    --header 'Content-Type: application/json' \
    --data '
    overlay:
        image: siderolabs/sbc-rockchip
        name: turingrk1
    customization:
        extraKernelArgs:
            - talos.hostname='${HOSTNAME}'
        systemExtensions:
            officialExtensions:
                - siderolabs/iscsi-tools
    ' | jq --raw-output '.id'
