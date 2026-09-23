#!/bin/sh
set -e

while getopts b:c:n:v: flag;
do
    case ${flag} in
        b) BOARD=${OPTARG} ;;
        c) TALOS_CONFIG=${OPTARG} ;;
        n) NODE_NAME=${OPTARG} ;;
        v) TALOS_VERSION=${OPTARG} ;;
        *) exit 1 ;;
    esac
done

SCHEMATIC_ID=$(sh "$(dirname "$0")/${BOARD}/gen-schematic-id.sh" "${NODE_NAME}")
INSTALLER_IMAGE="factory.talos.dev/metal-installer/${SCHEMATIC_ID}:${TALOS_VERSION}"

NODE_IP=$(kubectl get node "${NODE_NAME}" -o yaml | yq '.status.addresses[] | select(.type == "InternalIP") | .address')

echo "Upgrade node '${NODE_NAME}' to Talos version ${TALOS_VERSION}.."
talosctl upgrade --talosconfig ${TALOS_CONFIG} --nodes ${NODE_IP} --image ${INSTALLER_IMAGE} --preserve --wait
echo "Upgraded node '${NODE_NAME}' to Talos version ${TALOS_VERSION}."
