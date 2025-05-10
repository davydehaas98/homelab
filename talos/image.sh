TALOS_VERSION=v1.9.5
HOSTNAME=$1

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
    ' | jq -r '.id')

echo $ID    

# Retrieve image
curl https://factory.talos.dev/image/${ID}/${TALOS_VERSION}/metal-arm64.raw.xz \
    -o ${HOSTNAME}.metal-arm64.raw.xz

# Decompress .xz file
xz -d -f -v ${HOSTNAME}.metal-arm64.raw.xz
