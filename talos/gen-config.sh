#!/bin/sh
set -e

KUBERNETES_VERSION=1.34.11

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

CLUSTER_ENDPOINT="https://${NODE_NAME}:6443"

echo "Generating Talos config for '${NODE_NAME}'.."

CONFIG_PATCHES="--config-patch @${BOARD}/nodes/${NODE_NAME}.yaml --config-patch @patches/cluster.yaml"
if [ "${NODE_TYPE}" = "controlplane" ]; then
    CONFIG_PATCHES="${CONFIG_PATCHES} --config-patch @patches/controlplane.yaml"
fi

talosctl gen config \
    ${CLUSTER_NAME} ${CLUSTER_ENDPOINT} \
    --output gen/${NODE_NAME}.yaml \
    --output-types ${NODE_TYPE} \
    --with-cluster-discovery \
    --with-secrets gen/secrets.yaml \
    ${CONFIG_PATCHES} \
    --kubernetes-version ${KUBERNETES_VERSION} \
    --force

echo "Generated config for '${NODE_NAME}' at gen/${NODE_NAME}.yaml"
