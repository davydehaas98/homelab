#!/bin/sh
set -e
# Machine configs contain the cluster secrets, keep them private to your user
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

# The patch of the node is the single source of its type
NODE_TYPE=$(sed -n '/^machine:/,/^---/s/^  type: //p' "${BOARD}/nodes/${NODE_NAME}.yaml")
if [ -z "${NODE_TYPE}" ]; then
    echo "No machine.type in ${BOARD}/nodes/${NODE_NAME}.yaml"
    exit 1
fi

# patches/cluster.yaml is the single source of the control plane endpoint (and so of the VIP)
CLUSTER_ENDPOINT=$(sed -n 's/^endpoint: //p' patches/cluster.yaml)
CLUSTER_IP=${CLUSTER_ENDPOINT#https://}
CLUSTER_IP=${CLUSTER_IP%:*}

echo "Generating Talos config for '${NODE_NAME}'.."

CONFIG_PATCHES="--config-patch @patches/cluster.yaml"
if [ "${NODE_TYPE}" = "controlplane" ]; then
    mkdir -p gen
    sed "s/__CLUSTER_IP__/${CLUSTER_IP}/" patches/controlplane.yaml > gen/${NODE_NAME}.controlplane.yaml
    CONFIG_PATCHES="${CONFIG_PATCHES} --config-patch @gen/${NODE_NAME}.controlplane.yaml"
fi
# The node patch goes last, so its taints survive the cluster patch removing the default ones
CONFIG_PATCHES="${CONFIG_PATCHES} --config-patch @${BOARD}/nodes/${NODE_NAME}.yaml"

talosctl gen config \
    ${CLUSTER_NAME} ${CLUSTER_ENDPOINT} \
    --output gen/${NODE_NAME}.yaml \
    --output-types ${NODE_TYPE} \
    --with-cluster-discovery \
    --with-secrets gen/secrets.yaml \
    ${CONFIG_PATCHES} \
    --force

echo "Generated config for '${NODE_NAME}' at gen/${NODE_NAME}.yaml"
