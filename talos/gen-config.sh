#!/bin/sh

while getopts ac:k:i:n:t: flag;
do
    case $flag in
        a) APPLY="true" ;;
        c) CLUSTER_NAME=${OPTARG} ;;
        k) KUBERNETES_VERSION=${OPTARG} ;;
        i) NODE_IP=${OPTARG} ;;
        n) NODE_NUMBER=${OPTARG} ;;
        t) NODE_TYPE=${OPTARG} ;;
        *) exit 1 ;;
    esac
done

CLUSTER_ENDPOINT="https://${NODE_IP}:6443"
NODE_NAME="${NODE_TYPE}-${NODE_NUMBER}"


echo "Generating Talos config for '${NODE_NAME}'.."
talosctl gen config \
    $CLUSTER_NAME $CLUSTER_ENDPOINT \
    --output gen/${NODE_NAME}.yaml \
    --output-types ${NODE_TYPE} \
    --with-cluster-discovery \
    --with-secrets gen/secrets.yaml \
    --config-patch @nodes/${NODE_NAME}.yaml \
    --config-patch @patches/cluster.yaml \
    --config-patch @patches/rk1-all.yaml \
    --kubernetes-version ${KUBERNETES_VERSION} \
    --force

if [ $APPLY ]; then
    echo "Applying config for '${NODE_NAME}'"
    talosctl apply-config \
        -n $NODE_IP \
        -f gen/${NODE_NAME}.yaml
else
    echo "Skipped talosctl apply-config."
fi
