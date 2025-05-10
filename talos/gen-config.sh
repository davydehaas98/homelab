#!/bin/sh

KUBERNETES_VERSION=1.31.7

while getopts ac:n:t: flag;
do
    case ${flag} in
        a) APPLY="true" ;;
        c) CLUSTER_NAME=${OPTARG} ;;
        n) NODE_NAME=${OPTARG} ;;
        t) NODE_TYPE=${OPTARG} ;;
        *) exit 1 ;;
    esac
done

CLUSTER_ENDPOINT="https://${NODE_NAME}:6443"

echo "Generating Talos config for '${NODE_NAME}'.."

talosctl gen config \
    ${CLUSTER_NAME} ${CLUSTER_ENDPOINT} \
    --output gen/${NODE_NAME}.yaml \
    --output-types ${NODE_TYPE} \
    --with-cluster-discovery \
    --with-secrets gen/secrets.yaml \
    --config-patch @nodes/${NODE_NAME}.yaml \
    --config-patch @patches/cluster.yaml \
    --kubernetes-version ${KUBERNETES_VERSION} \
    --force

if [ ${APPLY} ]; then
    echo "Applying config for '${NODE_NAME}'"
    talosctl apply-config \
        --nodes ${NODE_NAME} \
        --file gen/${NODE_NAME}.yaml \
        --mode reboot
else
    echo "Skipped talosctl apply-config."
fi
