#!/bin/sh
set -e

cd "$(dirname "$0")"

while getopts b:c:n:t: flag;
do
    case ${flag} in
        b) BOARD=${OPTARG} ;;
        c) CLUSTER_NAME=${OPTARG} ;;
        n) NODE_NAME=${OPTARG} ;;
        t) NODE_TYPE=${OPTARG} ;;
        *) exit 1 ;;
    esac
done

# patches/cluster.yaml is the single source of the control plane endpoint (and so of the VIP)
CLUSTER_ENDPOINT=$(sed -n 's/^endpoint: //p' patches/cluster.yaml)
CLUSTER_IP=${CLUSTER_ENDPOINT#https://}
CLUSTER_IP=${CLUSTER_IP%:*}

echo "Generating Talos config for '${NODE_NAME}'.."

CONFIG_PATCHES="--config-patch @${BOARD}/nodes/${NODE_NAME}.yaml --config-patch @patches/cluster.yaml"
if [ "${NODE_TYPE}" = "controlplane" ]; then
    mkdir -p gen
    sed "s/__CLUSTER_IP__/${CLUSTER_IP}/" patches/controlplane.yaml > gen/${NODE_NAME}.controlplane.yaml
    CONFIG_PATCHES="${CONFIG_PATCHES} --config-patch @gen/${NODE_NAME}.controlplane.yaml"
fi

talosctl gen config \
    ${CLUSTER_NAME} ${CLUSTER_ENDPOINT} \
    --output gen/${NODE_NAME}.yaml \
    --output-types ${NODE_TYPE} \
    --with-cluster-discovery \
    --with-secrets gen/secrets.yaml \
    ${CONFIG_PATCHES} \
    --force

echo "Generated config for '${NODE_NAME}' at gen/${NODE_NAME}.yaml"
