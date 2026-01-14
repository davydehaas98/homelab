#
# This shell script will generate an image schemantic ID and download it from factory.talos.dev
#

TALOS_VERSION=v1.12.1
HOSTNAME=$1

echo "
Generating Talos image for hostname: '${HOSTNAME}' with Talos version: '${TALOS_VERSION}' ..
"

# Retrieve image schematic ID
ID=$(curl https://factory.talos.dev/schematics \
    --header 'Content-Type: application/json' \
    --data '
    overlay:
        image: siderolabs/sbc-rockchip
        name: turingrk1
    customization:
        extraKernelArgs:
            - talos.hostname='${HOSTNAME}'
        systemExtensions:
            officialExtensions:
                - siderolabs/iscsi-tools
    ' | jq --raw-output '.id')

# Retrieve image
export WEBSITE=https://factory.talos.dev/image/${ID}/${TALOS_VERSION}/metal-arm64.raw.xz
export IMAGE=${HOSTNAME}.metal-arm64.raw

echo "
Retrieving image from '${WEBSITE}' ..
"

curl --location ${WEBSITE} --output ${IMAGE}.xz

echo "
Decompressing image '${IMAGE}.xz' ..
"

# Decompress .xz file
xz --decompress --force --verbose ${IMAGE}.xz

echo "
Image downloaded and decompressed to '${IMAGE}'
"