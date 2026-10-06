#!/bin/sh
set -e
#
# Generates cluster secrets (once) and the talosconfig, merges it into your
# local talosctl config, and points the endpoint at a real node until bootstrap
# brings up the control plane VIP.
#
# Usage: sh gen-talosconfig.sh -c <cluster-name> -n <node-name>

cd "$(dirname "$0")"

while getopts c:n: flag;
do
    case ${flag} in
        c) CLUSTER_NAME=${OPTARG} ;;
        n) NODE_NAME=${OPTARG} ;;
        *) exit 1 ;;
    esac
done

# patches/cluster.yaml is the single source of the control plane endpoint (the VIP)
CLUSTER_ENDPOINT=$(sed -n 's/^endpoint: //p' patches/cluster.yaml)

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

# The endpoint is the control plane VIP, which only comes alive after bootstrap
# succeeds. Point the endpoint at a real control plane node until then.
talosctl config endpoint ${NODE_NAME}

echo "Merged talosconfig, endpoint set to '${NODE_NAME}'"
