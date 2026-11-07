#!/bin/sh
set -e
umask 077

cd "$(dirname "$0")"

while getopts b:c:n: flag;
do
    case ${flag} in
        b) BOARD=${OPTARG} ;;
        c) CLUSTER_NAME=${OPTARG} ;;
        n) NODE_NAME=${OPTARG} ;;
        *) exit 1 ;;
    esac
done

NODE_TYPE=$(sed -n '/^machine:/,/^---/s/^  type: //p' "${BOARD}/nodes/${NODE_NAME}.yaml")
if [ -z "${NODE_TYPE}" ]; then
    echo "No machine.type in ${BOARD}/nodes/${NODE_NAME}.yaml"
    exit 1
fi

CLUSTER_ENDPOINT=$(sed -n 's/^endpoint: //p' patches/cluster.yaml)
CLUSTER_IP=${CLUSTER_ENDPOINT#https://}
CLUSTER_IP=${CLUSTER_IP%:*}

# The versions tuppr upgrades the cluster to, else a new config would bring talosctl's defaults
TUPPR_VALUES=../kubernetes/core/tuppr/values.yaml
KUBERNETES_VERSION=$(sed -n '/^kubernetes:/,/^[^ ]/s/^    tag: v//p' ${TUPPR_VALUES})
TALOS_VERSION=$(sed -n '/^talos:/,/^[^ ]/s/^    tag: //p' ${TUPPR_VALUES})
if [ -z "${KUBERNETES_VERSION}" ] || [ -z "${TALOS_VERSION}" ]; then
    echo "No Kubernetes or Talos version in ${TUPPR_VALUES}"
    exit 1
fi

# The node's own schematic, with its overlay and extensions, as upgrade-talos.sh uses it
SCHEMATIC_ID=$(sh ${BOARD}/gen-schematic-id.sh ${NODE_NAME})
if [ -z "${SCHEMATIC_ID}" ]; then
    echo "No schematic for '${NODE_NAME}' from factory.talos.dev"
    exit 1
fi
INSTALLER_IMAGE="factory.talos.dev/metal-installer/${SCHEMATIC_ID}:${TALOS_VERSION}"

# The VIP goes on the node's DHCP interface
LINK=$(sed -n '/^kind: DHCPv4Config$/,/^---/s/^name: //p' "${BOARD}/nodes/${NODE_NAME}.yaml" | head -1)

echo "Generating Talos config for '${NODE_NAME}' (Talos ${TALOS_VERSION}, Kubernetes ${KUBERNETES_VERSION}).."

CONFIG_PATCHES="--config-patch @patches/cluster.yaml"
if [ "${NODE_TYPE}" = "controlplane" ]; then
    if [ -z "${LINK}" ]; then
        echo "No DHCPv4Config in ${BOARD}/nodes/${NODE_NAME}.yaml for the VIP"
        exit 1
    fi
    mkdir -p gen
    sed -e "s/__CLUSTER_IP__/${CLUSTER_IP}/" -e "s/__LINK__/${LINK}/" patches/controlplane.yaml \
        > gen/${NODE_NAME}.controlplane.yaml
    CONFIG_PATCHES="${CONFIG_PATCHES} --config-patch @gen/${NODE_NAME}.controlplane.yaml"
fi
# Last, so its taints survive the cluster patch removing the default ones
CONFIG_PATCHES="${CONFIG_PATCHES} --config-patch @${BOARD}/nodes/${NODE_NAME}.yaml"

talosctl gen config \
    ${CLUSTER_NAME} ${CLUSTER_ENDPOINT} \
    --output gen/${NODE_NAME}.yaml \
    --output-types ${NODE_TYPE} \
    --kubernetes-version ${KUBERNETES_VERSION} \
    --install-image ${INSTALLER_IMAGE} \
    --with-cluster-discovery \
    --with-secrets gen/secrets.yaml \
    ${CONFIG_PATCHES} \
    --force

echo "Generated config for '${NODE_NAME}' at gen/${NODE_NAME}.yaml"
