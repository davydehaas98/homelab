#!/bin/sh
set -e

cd "$(dirname "$0")"

while getopts b:n:v: flag;
do
    case ${flag} in
        b) BOARD=${OPTARG} ;;
        n) NODE_NAME=${OPTARG} ;;
        v) TALOS_VERSION=${OPTARG} ;;
        *) exit 1 ;;
    esac
done

SCHEMATIC_ID=$(sh ${BOARD}/gen-schematic-id.sh ${NODE_NAME})
INSTALLER_IMAGE="factory.talos.dev/metal-installer/${SCHEMATIC_ID}:${TALOS_VERSION}"

echo "Upgrading '${NODE_NAME}' to Talos ${TALOS_VERSION}.."
talosctl upgrade \
    --nodes ${NODE_NAME} \
    --image ${INSTALLER_IMAGE}
echo "Upgraded '${NODE_NAME}' to Talos ${TALOS_VERSION}"
