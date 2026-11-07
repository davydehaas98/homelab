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

# The version tuppr upgrades the cluster to, else a new config would bring talosctl's default
KUBERNETES_VERSION=$(sed -n '/^kubernetes:/,/^[^ ]/s/^    tag: v//p' ../kubernetes/core/tuppr/values.yaml)
if [ -z "${KUBERNETES_VERSION}" ]; then
    echo "No Kubernetes version in kubernetes/core/tuppr/values.yaml"
    exit 1
fi

echo "Generating Talos config for '${NODE_NAME}' (Kubernetes ${KUBERNETES_VERSION}).."

CONFIG_PATCHES="--config-patch @patches/cluster.yaml"
if [ "${NODE_TYPE}" = "controlplane" ]; then
    mkdir -p gen
    sed "s/__CLUSTER_IP__/${CLUSTER_IP}/" patches/controlplane.yaml > gen/${NODE_NAME}.controlplane.yaml
    CONFIG_PATCHES="${CONFIG_PATCHES} --config-patch @gen/${NODE_NAME}.controlplane.yaml"
fi
# Last, so its taints survive the cluster patch removing the default ones
CONFIG_PATCHES="${CONFIG_PATCHES} --config-patch @${BOARD}/nodes/${NODE_NAME}.yaml"

talosctl gen config \
    ${CLUSTER_NAME} ${CLUSTER_ENDPOINT} \
    --output gen/${NODE_NAME}.yaml \
    --output-types ${NODE_TYPE} \
    --kubernetes-version ${KUBERNETES_VERSION} \
    --with-cluster-discovery \
    --with-secrets gen/secrets.yaml \
    ${CONFIG_PATCHES} \
    --force

echo "Generated config for '${NODE_NAME}' at gen/${NODE_NAME}.yaml"
