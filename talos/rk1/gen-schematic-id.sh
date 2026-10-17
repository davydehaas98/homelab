#!/bin/bash
set -euo pipefail

NODE_NAME=$1

curl -s https://factory.talos.dev/schematics \
    --header 'Content-Type: application/json' \
    --data '
    overlay:
        image: siderolabs/sbc-rockchip
        name: turingrk1
    customization:
        extraKernelArgs:
            - talos.hostname='${NODE_NAME}'
        systemExtensions:
            officialExtensions:
                - siderolabs/iscsi-tools
                - siderolabs/util-linux-tools
    ' | jq --raw-output '.id'
