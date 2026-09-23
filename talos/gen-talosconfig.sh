#!/bin/sh
set -e
#
# Generates cluster secrets (once) and the talosconfig, merges it into your
# local talosctl config, and points the endpoint at a real node until bootstrap
# brings up the control plane VIP.
#
# Usage: sh gen-talosconfig.sh -c <cluster-name> -i <cluster-ip> -n <node-name>

while getopts c:i:n: flag;
do
    case ${flag} in
        c) CLUSTER_NAME=${OPTARG} ;;
        i) CLUSTER_IP=${OPTARG} ;;
        n) NODE_NAME=${OPTARG} ;;
        *) exit 1 ;;
    esac
done

CLUSTER_ENDPOINT="https://${CLUSTER_IP}:6443"

if [ ! -f gen/secrets.yaml ]; then
    echo "Generating cluster secrets.."
    mkdir -p gen
    talosctl gen secrets -o gen/secrets.yaml
    echo "Generated cluster secrets at gen/secrets.yaml"
else
    echo "Cluster secrets already exist at gen/secrets.yaml, skipping generation"
fi

echo "Generating talosconfig.."
talosctl gen config \
    ${CLUSTER_NAME} ${CLUSTER_ENDPOINT} \
    --output-types talosconfig \
    --output talosconfig \
    --with-secrets gen/secrets.yaml \
    --force
echo "Generated talosconfig"

talosctl config merge talosconfig

# CLUSTER_IP is the control plane VIP, which only comes alive after bootstrap
# succeeds. Point the endpoint at a real control plane node until then.
talosctl config endpoint ${NODE_NAME}

echo "Merged talosconfig, endpoint set to '${NODE_NAME}'"
