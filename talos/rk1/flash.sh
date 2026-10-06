#!/bin/sh
set -e
#
# Flashes a Talos image to a Turing Pi 2 node slot and powers it on.
#
# Usage: sh flash.sh <hostname> <slot>
#   hostname  matches the image built by gen-image.sh, e.g. jotunheim_1
#   slot      Turing Pi node slot number (1-4)
#
# Requires TPI_HOST / TPI_USER / TPI_PASS to be set.

cd "$(dirname "$0")/.."

NODE_NAME=$1
SLOT=$2

if [ -z "${NODE_NAME}" ] || [ -z "${SLOT}" ]; then
    echo "Usage: sh flash.sh <hostname> <slot>"
    exit 1
fi

if [ -z "${TPI_HOST}" ] || [ -z "${TPI_USER}" ] || [ -z "${TPI_PASS}" ]; then
    echo "TPI_HOST, TPI_USER and TPI_PASS must be set"
    exit 1
fi

IMAGE="gen/${NODE_NAME}.metal-arm64.raw"

if [ ! -f "${IMAGE}" ]; then
    echo "Image '${IMAGE}' not found, run rk1/gen-image.sh <version> ${NODE_NAME} first"
    exit 1
fi

echo "Flashing '${IMAGE}' to node ${SLOT} ('${NODE_NAME}') .."
if ! tpi flash -i "${IMAGE}" -n "${SLOT}" \
    --host "${TPI_HOST}" --user "${TPI_USER}" --password "${TPI_PASS}"; then
    echo "Failed to flash node ${SLOT} ('${NODE_NAME}')"
    exit 1
fi

echo "Flashed node ${SLOT} ('${NODE_NAME}'), powering on .."
if tpi power on -n "${SLOT}" \
    --host "${TPI_HOST}" --user "${TPI_USER}" --password "${TPI_PASS}"; then
    echo "Node ${SLOT} ('${NODE_NAME}') powered on"
else
    echo "Failed to power on node ${SLOT} ('${NODE_NAME}')"
    exit 1
fi
