#!/bin/sh

while getopts c:n:t:v: flag;
do
    case ${flag} in
        c) TALOS_CONFIG=${OPTARG} ;;
        n) NODE_NUMBER=${OPTARG} ;;
        t) NODE_TYPE=${OPTARG} ;;
        v) TALOS_VERSION=${OPTARG} ;;
        *) exit 1 ;;
    esac
done

INSTALLER_IMAGE="ghcr.io/davydehaas98/homelab/talos-installer:${TALOS_VERSION}"

docker manifest inspect ${INSTALLER_IMAGE} > /dev/null 2>&1

if [ $? -ne 0 ]; then
    echo "Custom Talos installer does not exist, aborting.."
    exit 1;
else
    echo "Custom Talos installer already exists, skipping build.."
fi

NODE_NAME="${NODE_TYPE}-${NODE_NUMBER}"
NODE_IP=$(kubectl get node "${NODE_NAME}" -o yaml | yq '.status.addresses[] | select(.type == "InternalIP") | .address')

echo "Upgrade node '${NODE_NAME}' to Talos version ${TALOS_VERSION}.."
talosctl upgrade --talosconfig ${TALOS_CONFIG} --nodes ${NODE_IP} --image ${INSTALLER_IMAGE} --preserve --wait
echo "Upgraded node '${NODE_NAME}' to Talos version ${TALOS_VERSION}."
