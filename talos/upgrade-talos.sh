#!/bin/sh

while getopts c:n:t:v: flag;
do
    case ${flag} in
        c) TALOS_CONFIG=${OPTARG} ;;
        n) NODE_NUMBER=${OPTARG} ;;
        t) NODE_TYPE=${OPTARG} ;;
        v) TALOS_VERSION=${OPTARG} ;;
        *) exit 1 ;;
    esac
done

INSTALLER_IMAGE="ghcr.io/davydehaas98/homelab/talos-installer:${TALOS_VERSION}"

docker manifest inspect ${INSTALLER_IMAGE} > /dev/null 2>&1

if [ $? -ne 0 ]; then
    echo "Creating custom ISO and installer for Talos version '${TALOS_VERSION}'.."

    ISCSI_IMAGE=$(crane export ghcr.io/siderolabs/extensions:${TALOS_VERSION} | tar x -O image-digests | grep iscsi-tools)
    echo "Using system-extension-image (iscsi-tools): ${ISCSI_IMAGE}"

    UTIL_IMAGE=$(crane export ghcr.io/siderolabs/extensions:${TALOS_VERSION} | tar x -O image-digests | grep util-linux-tools)
    echo "Using system-extension-image (util-linux-tools): ${UTIL_IMAGE}"

    RK3588_IMAGE=$(crane export ghcr.io/nberlee/extensions:${TALOS_VERSION} | tar x -O image-digests | grep rk3588)
    echo "Using system-extension-image (rk3588): ${RK3588_IMAGE}"

    mkdir _images
    
    docker run --rm -t -v ./_images:/out --privileged ghcr.io/nberlee/imager:${TALOS_VERSION} iso \
        --base-installer-image ghcr.io/nberlee/installer:${TALOS_VERSION}-rk3588 \
        --system-extension-image ${ISCSI_IMAGE} \
        --system-extension-image ${UTIL_IMAGE} \
        --system-extension-image ${RK3588_IMAGE}

    docker run --rm -t -v ./_images:/out --privileged ghcr.io/nberlee/imager:"${TALOS_VERSION}" installer \
        --base-installer-image ghcr.io/nberlee/installer:"${TALOS_VERSION}"-rk3588 \
        --system-extension-image ${ISCSI_IMAGE} \
        --system-extension-image ${UTIL_IMAGE} \
        --system-extension-image ${RK3588_IMAGE}
    
    echo "Pushing custom installer for Talos version '${TALOS_VERSION} to '${INSTALLER_IMAGE}'.."
    crane push ./_images/installer-arm64.tar ${INSTALLER_IMAGE}
    echo "Pushed custom installer for Talos version '${TALOS_VERSION} to '${INSTALLER_IMAGE}'."

    rm -rf _images
else
    echo "Custom Talos installer already exists, skipping build.."
fi

NODE_NAME="${NODE_TYPE}-${NODE_NUMBER}"
NODE_IP=$(kubectl get node "${NODE_NAME}" -o yaml | yq '.status.addresses[] | select(.type == "InternalIP") | .address')

echo "Upgrade node '${NODE_NAME}' to Talos version ${TALOS_VERSION}.."
talosctl upgrade --talosconfig ${TALOS_CONFIG} --nodes ${NODE_IP} --image ${INSTALLER_IMAGE} --preserve --wait
echo "Upgraded node '${NODE_NAME}' to Talos version ${TALOS_VERSION}."
