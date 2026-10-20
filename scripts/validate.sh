#!/bin/sh
set -e
#
# Validates what CI does not: the root chart, and for each given app its dependencies, lint and render, which must
# contain a Namespace (Argo CD does not create one). With -t it also validates and format-checks the Terraform of
# davydehaas.dev, which needs no credentials. Run it in the dev container (.devcontainer/README.md).
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

echo "Rendering chart/.."
helm template chart > /dev/null

for APP in "$@"; do
    echo "Validating ${APP}.."
    helm dependency update "kubernetes/${APP}" > /dev/null
    helm lint "kubernetes/${APP}"
    if ! helm template "kubernetes/${APP}" --api-versions monitoring.coreos.com/v1 | grep -q '^kind: Namespace$'; then
        echo "The render of ${APP} has no Namespace" >&2
        exit 1
    fi
done

if [ -n "${TERRAFORM}" ]; then
    echo "Validating terraform.."
    cd terraform/cloudflare/davydehaas.dev
    # Keep the lock file out of the working tree unless it is there already
    [ -f .terraform.lock.hcl ] && LOCKED=1
    terraform init -backend=false > /dev/null
    terraform validate
    terraform fmt -check
    [ -n "${LOCKED}" ] || rm -f .terraform.lock.hcl
fi

echo "Valid"
