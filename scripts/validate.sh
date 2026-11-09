#!/bin/sh
set -e
#
# Lints the plain YAML and renders the given apps, checking that their images publish the architecture of their node;
# -t also validates Terraform.
#
# Usage: sh scripts/validate.sh [-t] [<group>/<app> ...]

cd "$(dirname "$0")/.."

while getopts t flag;
do
    case ${flag} in
        t) TERRAFORM=1 ;;
        *) exit 1 ;;
    esac
done
shift $((OPTIND - 1))

RENDER=$(mktemp)
IMAGES=$(mktemp)
trap 'rm -f "${RENDER}" "${IMAGES}"' EXIT

# Prints each workload's image with the architectures it needs: amd64 with a volume (midgard-0), both for a
# DaemonSet, arm64 for the rest (the RK1 nodes), unless a nodeSelector names one
list_images() {
    yq eval -N '
        select(.kind | test("^(Deployment|StatefulSet|DaemonSet|Job|CronJob|Pod)$")) |
        .kind as $kind |
        (.spec.volumeClaimTemplates // []) as $claims |
        (.spec.jobTemplate.spec.template.spec // .spec.template.spec // .spec) as $pod |
        (
            if $pod.nodeSelector."kubernetes.io/arch" then $pod.nodeSelector."kubernetes.io/arch"
            elif $kind == "DaemonSet" then "amd64,arm64"
            elif ($claims | length) > 0 or ([$pod.volumes[] | select(.persistentVolumeClaim)] | length) > 0 then "amd64"
            else "arm64"
            end
        ) as $archs |
        (($pod.initContainers // []) + $pod.containers)[] | $archs + "|" + .image
    ' "$1" | sort -u
}

image_archs() {
    MANIFEST=$(crane manifest "$1") || return 1
    if echo "${MANIFEST}" | jq -e '.manifests' > /dev/null; then
        echo "${MANIFEST}" | jq -r '.manifests[].platform.architecture'
    else
        crane config "$1" | jq -r '.architecture'
    fi
}

check_images() {
    STATUS=0
    while IFS='|' read -r ARCHS IMAGE; do
        if ! FOUND=$(image_archs "${IMAGE}"); then
            echo "Error: cannot read the manifest of ${IMAGE}"
            STATUS=1
            continue
        fi
        for ARCH in $(echo "${ARCHS}" | tr ',' ' '); do
            if ! echo "${FOUND}" | grep -qx "${ARCH}"; then
                echo "Error: ${IMAGE} has no ${ARCH} image"
                STATUS=1
            fi
        done
    done < "$1"
    return "${STATUS}"
}

echo "Linting YAML.."
git ls-files -z '*.yaml' '*.yml' | xargs -0 yamllint

for APP in "$@"; do
    echo "Validating ${APP}.."
    helm dependency update "kubernetes/${APP}" > /dev/null
    helm lint "kubernetes/${APP}"
    helm template "kubernetes/${APP}" --api-versions monitoring.coreos.com/v1 > "${RENDER}"
    if ! grep -q '^kind: Namespace$' "${RENDER}"; then
        echo "Warning: the render of ${APP} has no Namespace, which then has to come from another app"
    fi
    list_images "${RENDER}" > "${IMAGES}"
    if ! check_images "${IMAGES}"; then
        FAILED=1
    fi
done

if [ -n "${TERRAFORM}" ]; then
    echo "Validating terraform.."
    for STACK in terraform/cloudflare/davydehaas.dev terraform/cloudflare/davydehaas.nl terraform/devopsarr terraform/unifi; do
        (
            cd "${STACK}"
            [ -f .terraform.lock.hcl ] && LOCKED=1
            terraform init -backend=false > /dev/null
            terraform validate
            terraform fmt -check
            [ -n "${LOCKED}" ] || rm -f .terraform.lock.hcl
        )
    done
fi

if [ -n "${FAILED}" ]; then
    exit 1
fi

echo "Valid"
