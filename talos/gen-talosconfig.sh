#!/bin/sh
set -e
#
# Generates the cluster secrets (once) and the talosconfig, and merges it into ~/.talos/config.
#
# Usage: sh gen-talosconfig.sh -c <cluster-name> -n <node-name>

umask 077

cd "$(dirname "$0")"

while getopts c:n: flag;
do
    case ${flag} in
        c) CLUSTER_NAME=${OPTARG} ;;
        n) NODE_NAME=${OPTARG} ;;
        *) exit 1 ;;
    esac
done

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
    --output gen/talosconfig \
    --with-secrets gen/secrets.yaml \
    --force
echo "Generated talosconfig at gen/talosconfig"

talosctl config merge gen/talosconfig

# The VIP only comes alive after bootstrap
talosctl config endpoint ${NODE_NAME}

echo "Merged talosconfig, endpoint set to '${NODE_NAME}'"
