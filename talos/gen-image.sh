#!/bin/sh
set -e
#
# Downloads the node's image from factory.talos.dev.
#
# Usage: sh gen-image.sh -b <board> -n <node-name> -v <talos-version>

cd "$(dirname "$0")"

while getopts b:n:v: flag;
do
    case ${flag} in
        b) BOARD=${OPTARG} ;;
        n) NODE_NAME=${OPTARG} ;;
        v) TALOS_VERSION=${OPTARG} ;;
        *) exit 1 ;;
    esac
done

echo "
Generating Talos image.. (node: '${NODE_NAME}', version: '${TALOS_VERSION}')
"

ID=$(sh ${BOARD}/gen-schematic-id.sh "${NODE_NAME}")

case ${BOARD} in
    i5-10600k) IMAGE_TYPE=metal-amd64.raw ;;
    *) IMAGE_TYPE=metal-arm64.raw ;;
esac

WEBSITE=https://factory.talos.dev/image/${ID}/${TALOS_VERSION}/${IMAGE_TYPE}
IMAGE=gen/${NODE_NAME}.${IMAGE_TYPE}

mkdir -p gen

echo "
Retrieving image from '${WEBSITE}.xz' ..
"
curl --location ${WEBSITE}.xz --output ${IMAGE}.xz

echo "
Decompressing image '${IMAGE}.xz' ..
"

xz --decompress --force --verbose ${IMAGE}.xz

echo "
Image downloaded and decompressed to '${IMAGE}'
"

echo "
Generated Talos image. (node: '${NODE_NAME}', version: '${TALOS_VERSION}')
"
