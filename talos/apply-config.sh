#!/bin/sh
set -e

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

sh gen-config.sh -b ${BOARD} -c ${CLUSTER_NAME} -n ${NODE_NAME} -t ${NODE_TYPE}

echo "Applying config for '${NODE_NAME}'"
if OUTPUT=$(talosctl apply-config \
    --nodes ${NODE_NAME} \
    --file gen/${NODE_NAME}.yaml \
    --mode auto 2>&1); then
    echo "${OUTPUT}"
    echo "Applied config for '${NODE_NAME}'"
    exit 0
fi
echo "${OUTPUT}"

if echo "${OUTPUT}" | grep -q "tls: certificate required"; then
    echo "'${NODE_NAME}' is still in maintenance mode, retrying with --insecure"
    if talosctl apply-config \
        --nodes ${NODE_NAME} \
        --file gen/${NODE_NAME}.yaml \
        --mode auto \
        --insecure; then
        echo "Applied config for '${NODE_NAME}'"
        exit 0
    fi
fi

echo "Failed to apply config for '${NODE_NAME}'"
exit 1
